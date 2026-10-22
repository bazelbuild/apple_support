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

load(
    "//rules/private:apple_genrule.bzl",
    _apple_genrule_inner = "apple_genrule",
)

# buildozer: disable=function-docstring-args
def apple_genrule(
        name,
        *,
        outs,
        cmd,
        executable = False,
        srcs = None,
        tools = None,
        message = None,
        no_sandbox = None,
        toolchains = None,
        expect_failure = None,
        **kwargs):
    """Genrule which provides make variables and an Apple environment on macOS."""

    # This split/indirection traces back to cl/128714692 and b/30413353.
    inner_kwargs = dict(kwargs)
    if executable:
        if type(outs) == "depset":
            fail("apple_genrule executable outputs must be a list or tuple")
        if expect_failure != None:
            fail("apple_genrule executable rules do not support expect_failure")
        if len(outs) != 1:
            fail("apple_genrule, if executable, must have exactly one output")
        output = outs[0]
        if type(output) != "string":
            fail("apple_genrule executable output must be a string")
        intermediate_out = output + ".nonexecutable"
        inner_name = name + "_nonexecutable"
        inner_outs = [intermediate_out]

        # The intermediate rule is an implementation detail.
        inner_kwargs["visibility"] = ["//visibility:private"]
    else:
        inner_name = name
        inner_outs = outs

    _apple_genrule_inner(
        name = inner_name,
        outs = inner_outs,
        cmd = cmd,
        executable = executable,
        srcs = srcs,
        tools = tools,
        message = message,
        no_sandbox = no_sandbox,
        toolchains = toolchains,
        expect_failure = expect_failure,
        **inner_kwargs
    )
    if executable:
        # Only common attributes belong on the executable copy.
        if type(toolchains) == "select":
            fail("apple_genrule executable toolchains cannot be configurable")
        native.genrule(
            name = name,
            outs = outs,
            srcs = inner_outs,
            cmd = "cp $< $@",
            executable = True,
            toolchains = toolchains,
            **kwargs
        )
