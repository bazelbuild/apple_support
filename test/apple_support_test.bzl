# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Definition of a test rule to test apple_support."""

load(
    "@build_bazel_apple_support//lib:apple_support.bzl",
    "apple_support",
)

# Contents of the tool that writes the state of the action into a file. The first argument to this
# script is the path to the output file.
_TEST_TOOL_CONTENTS = """#!/bin/bash

set -eu

OUTPUT_FILE="$1"
shift

echo "XCODE_PATH_ENV=$DEVELOPER_DIR" > "$OUTPUT_FILE"
echo "SDKROOT_PATH_ENV=$SDKROOT" >> "$OUTPUT_FILE"

for arg in "$@"; do
    if [[ "$arg" == @* ]]; then
        cat "${arg:1}" >> "$OUTPUT_FILE"
    else
        echo "$arg" >> "$OUTPUT_FILE"
    fi
done
"""

# Template for the test script used to validate that the action outputs contain the expected
# values.
_TEST_SCRIPT_CONTENTS = """
#!/bin/bash

set -eu

FILES=(
    {file_paths}
)

function assert_contains_line() {{
    file="$1"
    contents="$2"

    if [[ -f "$file" ]]; then
      grep -Fxq "$contents" "$file" || \
          (echo "In file: $file"; \
           echo "Expected contents not found: $contents"; \
           echo "File contents:"; \
           cat "$file"; \
           exit 1)
    else
      echo "$file doesn't exist"
      exit 1
    fi
}}

function assert_not_contains() {{
    file="$1"
    contents="$2"

    if [[ -f "$file" ]]; then
      grep -Fq "$contents" "$file" || return 0
    else
      echo "$file doesn't exist"
      exit 1
    fi

    echo "In file: $file"
    echo "Contents found but not expected: $contents"
    echo "File contents:"
    cat "$file"
    exit 1
}}

XCODE_PATH_ENV="$DEVELOPER_DIR"
SDKROOT_PATH_ENV="$SDKROOT"

for file in "${{FILES[@]}}"; do
    assert_contains_line "$file" "XCODE_PATH_ENV=$XCODE_PATH_ENV"
    assert_contains_line "$file" "SDKROOT_PATH_ENV=$SDKROOT_PATH_ENV"
    assert_not_contains "$file" "{xcode_path_placeholder}"
    assert_not_contains "$file" "{sdkroot_path_placeholder}"
done

echo "Test passed"

exit 0
"""

def _apple_support_test_impl(ctx):
    """Implementation of the apple_support_test rule."""

    # Declare all the action outputs
    run_output = ctx.actions.declare_file(
        "{}_run_output".format(ctx.label.name),
    )
    run_output_xcode_path_in_args = ctx.actions.declare_file(
        "{}_run_output_xcode_path_in_args".format(ctx.label.name),
    )
    run_output_xcode_path_in_file = ctx.actions.declare_file(
        "{}_run_output_xcode_path_in_file".format(ctx.label.name),
    )
    run_shell_output = ctx.actions.declare_file(
        "{}_run_shell_output".format(ctx.label.name),
    )

    test_tool = ctx.actions.declare_file("{}_test_tool".format(ctx.label.name))
    ctx.actions.write(test_tool, _TEST_TOOL_CONTENTS, is_executable = True)

    # Create one action per possible combination of inputs to the apple_support.run and
    # apple_support.run_shell helper methods.
    apple_support.run(
        ctx,
        outputs = [run_output],
        executable = test_tool,
        arguments = [run_output.path],
    )

    apple_support.run(
        ctx,
        outputs = [run_output_xcode_path_in_args],
        executable = test_tool,
        arguments = [
            run_output_xcode_path_in_args.path,
            "XCODE_PATH_ARG={}".format(apple_support.path_placeholders.xcode()),
            "FRAMEWORKS_PATH_ARG={}".format(
                apple_support.path_placeholders.platform_frameworks(ctx),
            ),
            "SDKROOT_PATH_ARG={}".format(apple_support.path_placeholders.sdkroot()),
        ],
        xcode_path_resolve_level = apple_support.xcode_path_resolve_level.args,
    )

    action_args = ctx.actions.args()
    action_args.add(
        "XCODE_PATH_ARG={}".format(apple_support.path_placeholders.xcode()),
    )
    action_args.add(
        "FRAMEWORKS_PATH_ARG={}".format(apple_support.path_placeholders.platform_frameworks(ctx)),
    )
    action_args.add(
        "SDKROOT_PATH_ARG={}".format(apple_support.path_placeholders.sdkroot()),
    )
    action_args.set_param_file_format("multiline")
    action_args.use_param_file("@%s", use_always = True)

    apple_support.run(
        ctx,
        outputs = [run_output_xcode_path_in_file],
        executable = test_tool,
        arguments = [
            run_output_xcode_path_in_file.path,
            action_args,
        ],
        xcode_path_resolve_level = apple_support.xcode_path_resolve_level.args_and_files,
    )

    apple_support.run_shell(
        ctx,
        outputs = [run_shell_output],
        tools = [test_tool],
        command = ["/bin/bash", "-c", "{tool} {output}".format(
            output = run_shell_output.path,
            tool = test_tool.path,
        )],
    )

    test_files = [
        run_output,
        run_output_xcode_path_in_args,
        run_output_xcode_path_in_file,
        run_shell_output,
    ]

    test_script = ctx.actions.declare_file("{}_test_script".format(ctx.label.name))
    ctx.actions.write(test_script, _TEST_SCRIPT_CONTENTS.format(
        file_paths = "\n    ".join([x.short_path for x in test_files]),
        sdkroot_path_placeholder = apple_support.path_placeholders.sdkroot(),
        xcode_path_placeholder = apple_support.path_placeholders.xcode(),
    ), is_executable = True)

    return [
        testing.ExecutionInfo(apple_support.action_required_execution_requirements()),
        testing.TestEnvironment(apple_support.action_required_env(ctx)),
        DefaultInfo(
            executable = test_script,
            files = depset([run_output_xcode_path_in_args]),
            runfiles = ctx.runfiles(
                files = test_files,
            ),
        ),
    ]

apple_support_test = rule(
    implementation = _apple_support_test_impl,
    attrs = apple_support.action_required_attrs(),
    fragments = ["apple"],
    test = True,
)
