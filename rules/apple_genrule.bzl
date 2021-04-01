# Copyright 2017 The Bazel Authors. All rights reserved.
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

"""Genrule which provides Apple's Xcode environment."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("//lib:apple_support.bzl", "apple_support")

def _compute_make_variables(
        genfiles_dir,
        label,
        resolved_srcs,
        files_to_build):
    resolved_srcs_list = resolved_srcs.to_list()
    variables = {
        "OUTS": " ".join([x.path for x in files_to_build]),
        "SRCS": " ".join([x.path for x in resolved_srcs_list]),
    }
    if len(resolved_srcs_list) == 1:
        variables["<"] = resolved_srcs_list[0].path
    if len(files_to_build) == 1:
        variables["@"] = files_to_build[0].path
        variables["@D"] = files_to_build[0].dirname
    else:
        variables["@D"] = genfiles_dir.path + "/" + label.package
    return variables

def _apple_genrule_impl(ctx):
    if not ctx.outputs.outs:
        fail("apple_genrule must have one or more outputs", attr = "outs")
    files_to_build = ctx.outputs.outs

    if ctx.attr.executable and len(files_to_build) > 1:
        fail(
            "if genrules produce executables, they are allowed only one output. " +
            "If you need the executable=1 argument, then you should split this " +
            "genrule into genrules producing single outputs",
            attr = "executable",
        )

    resolved_srcs = depset(transitive = [dep.files for dep in ctx.attr.srcs])
    label_dict = {dep.label: dep.files.to_list() for dep in ctx.attr.srcs}

    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]

    resolved_inputs, argv, runfiles_manifests = ctx.resolve_command(
        command = ctx.attr.cmd,
        attribute = "cmd",
        expand_locations = True,
        make_variables = _compute_make_variables(
            ctx.genfiles_dir,
            ctx.label,
            resolved_srcs,
            files_to_build,
        ),
        tools = ctx.attr.tools,
        label_dict = label_dict,
        execution_requirements = xcode_config.execution_info(),
    )

    message = ctx.attr.message or "Executing apple_genrule"

    extra_args = {}
    if ctx.attr.no_sandbox:
        extra_args["execution_requirements"] = {"no-sandbox": "1"}

    apple_support.run_shell(
        actions = ctx.actions,
        xcode_config = xcode_config,
        apple_fragment = ctx.fragments.apple,
        inputs = depset(resolved_inputs, transitive = [resolved_srcs]),
        outputs = files_to_build,
        env = ctx.configuration.default_shell_env,
        command = " ".join(argv),
        progress_message = "%s %s" % (message, ctx.label),
        mnemonic = "Genrule",
        input_manifests = runfiles_manifests,
        **extra_args
    )

    return [
        DefaultInfo(
            files = depset(files_to_build),
            data_runfiles = ctx.runfiles(files = files_to_build),
        ),
    ]

_apple_genrule_inner = rule(
    implementation = _apple_genrule_impl,
    attrs = dicts.add(apple_support.action_required_attrs(), {
        "srcs": attr.label_list(allow_files = True),
        "outs": attr.output_list(mandatory = True),
        "cmd": attr.string(mandatory = True),
        "executable": attr.bool(default = False),
        "message": attr.string(),
        "no_sandbox": attr.bool(),
        "tools": attr.label_list(cfg = "exec", allow_files = True),
    }),
    exec_compatible_with = ["@platforms//os:macos"],
    output_to_genfiles = True,
    fragments = ["apple"],
)

def apple_genrule(
        name,
        cmd,
        executable = False,
        outs = [],
        srcs = [],
        message = None,
        tools = [],
        no_sandbox = False,
        **kwargs):
    """Genrule which provides Apple specific environment and make variables.

    This mirrors the native genrule except that it provides a different set of
    make variables. This rule will only run on a Mac.

    Example of use:

    ```
    load("@build_bazel_apple_support//rules:apple_genrule.bzl", "apple_genrule")

    apple_genrule(
        name = "world",
        outs = ["hi"],
        cmd = "touch $@",
    )
    ```

    This rule also does location expansion, much like the native genrule.
    For example, `$(location hi)` may be used to refer to the output in the
    above example.

    The set of make variables that are supported for this rule:

    * `OUTS`: The outs list. If you have only one output file, you can also use
              `$@`.
    * `SRCS`: The srcs list (or more precisely, the pathnames of the files
              corresponding to labels in the srcs list). If you have only one
              source file, you can also use `$<`.
    * `<`: srcs, if it's a single file.
    * `@`: outs, if it's a single file.
    * `@D`: The output directory. If there is only one filename in outs, this
            expands to the directory containing that file. If there are
            multiple filenames, this variable instead expands to the package's
            root directory in the genfiles tree, even if all the generated
            files belong to the same subdirectory.

    The following environment variables are added to the rule action:

    * `DEVELOPER_DIR`: The base developer directory as defined on Apple
                       architectures, most commonly used in invoking Apple
                       tools such as xcrun.
    * `SDKROOT`: The base SDK directory as defined on Apple architectures, most
                 commonly used in invoking Apple tools such as xcrun.

    Args:
      name: The name of the target.
      cmd: The command to run. Subject the variable substitution.
      executable: Boolean. Declare output to be executable. Setting this flag to
        1 means the output is an executable file and can be run using the run
        command. The genrule must produce exactly one output in this case.
      outs: A list of files generated by this rule. If the executable flag is
        set, outs must contain exactly one label.
      srcs: A list of inputs for this rule, such as source files to process.
      message: A progress message to be reported as the rule runs.
      tools: A list of tool dependencies for this rule, they will be available
        when the action is run.
      no_sandbox: If the sandbox should be disabled when the action is run.
      **kwargs: Extra args meant to just be the common rules for all rules
        (tags, etc.).
    """
    if executable:
        if len(outs) != 1:
            fail("apple_genrule, if executable, must have exactly one output")

        intermediate_out = outs[0] + ".nonexecutable"

        # Remove any visibility and make this sub rule private since it is an
        # implementation detail.
        sub_kwargs = dict(kwargs)
        sub_kwargs.pop("visibility", None)
        _apple_genrule_inner(
            name = name + "_nonexecutable",
            outs = [intermediate_out],
            cmd = cmd,
            srcs = srcs,
            message = message,
            tools = tools,
            no_sandbox = no_sandbox,
            executable = executable,
            visibility = ["//visibility:private"],
            **sub_kwargs
        )

        # Remove anything from kwargs that might have a meaning that isn't wanted
        # on the genrule that does the copy. Generally, we are just trying to
        # keep things like testonly, visibility, etc.
        trimmed_kwargs = dict(kwargs)
        trimmed_kwargs.pop("stamp", None)
        native.genrule(
            name = name,
            outs = outs,
            srcs = [intermediate_out],
            cmd = "cp $< $@",
            executable = True,
            **trimmed_kwargs
        )
    else:
        _apple_genrule_inner(
            name = name,
            outs = outs,
            cmd = cmd,
            srcs = srcs,
            message = message,
            tools = tools,
            executable = executable,
            no_sandbox = no_sandbox,
            **kwargs
        )
