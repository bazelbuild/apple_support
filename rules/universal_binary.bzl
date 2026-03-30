# Copyright 2021 The Bazel Authors. All rights reserved.
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

"""Implementation for macOS universal binary rule."""

load("//lib:lipo.bzl", "lipo")
load("//lib:transitions.bzl", "macos_universal_transition")

_LIPO_TOOLCHAIN_TYPE = "//rules/lipo:toolchain_type"

def _universal_binary_impl(ctx):
    inputs = [
        binary[DefaultInfo].files.to_list()[0]
        for binary in ctx.split_attr.binary.values()
    ]

    if not inputs:
        fail("Target (%s) `binary` label ('%s') does not provide any " +
             "file for universal binary" % (ctx.attr.name, ctx.attr.binary))

    output = ctx.actions.declare_file(ctx.label.name)

    if len(inputs) > 1:
        lipo_toolchain = ctx.toolchains[_LIPO_TOOLCHAIN_TYPE]
        if not lipo_toolchain:
            fail("{} requires a lipo toolchain to build a universal binary but no lipo toolchain was found.".format(ctx.attr.name))

        lipo.create(
            actions = ctx.actions,
            inputs = inputs,
            output = output,
            toolchain = lipo_toolchain.lipo_info,
        )

    else:
        # If the transition doesn't split, this is building for a non-macOS
        # target, so just create a symbolic link of the input binary.
        ctx.actions.symlink(target_file = inputs[0], output = output)

    runfiles = ctx.runfiles(files = ctx.files.binary)
    transitive_runfiles = [
        binary[DefaultInfo].default_runfiles
        for binary in ctx.split_attr.binary.values()
    ]
    runfiles = runfiles.merge_all(transitive_runfiles)

    return [
        DefaultInfo(
            executable = output,
            files = depset([output]),
            runfiles = runfiles,
        ),
    ]

universal_binary = rule(
    attrs = {
        "binary": attr.label(
            cfg = macos_universal_transition,
            doc = "Target to generate a 'fat' binary from.",
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    doc = """
This rule produces a multi-architecture ("fat") binary targeting Apple macOS
platforms *regardless* of the architecture of the macOS host platform. The
`lipo` tool is used to combine built binaries of multiple architectures.
""",
    executable = True,
    implementation = _universal_binary_impl,
    toolchains = [config_common.toolchain_type(_LIPO_TOOLCHAIN_TYPE, mandatory = False)],
)
