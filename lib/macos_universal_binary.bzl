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

load(":apple_support.bzl", "apple_support")
load(":lipo.bzl", "lipo")
load(":transitions.bzl", "macos_universal_transition")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

def _macos_universal_binary_impl(ctx):
    inputs = [
        binary.files.to_list()[0]
        for binary in ctx.split_attr.binary.values()
    ]

    if not inputs:
        fail("Target (%s) `binary` label ('%s') does not provide any " +
             "file for universal binary" % (ctx.attr.name, ctx.attr.binary))

    fat_binary = ctx.actions.declare_file(ctx.label.name)

    lipo.create(
        actions = ctx.actions,
        apple_fragment = ctx.fragments.apple,
        inputs = inputs,
        output = fat_binary,
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )

    return [
        DefaultInfo(
            executable = fat_binary,
            files = depset([fat_binary]),
        ),
    ]

macos_universal_binary = rule(
    attrs = dicts.add(
        apple_support.action_required_attrs(),
        {
            "binary": attr.label(
                cfg = macos_universal_transition,
                doc = "Target to generate a 'fat' binary from.",
                mandatory = True,
            ),
            "_allowlist_function_transition": attr.label(
                default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
            ),
        },
    ),
    doc = """
This rule produces a multi-architecture ("fat") binary targeting Apple macOS
platforms *regardless* the architecture of the host platform. The `lipo` tool
is used to combine built binaries of multiple architectures.
""",
    fragments = ["apple"],
    implementation = _macos_universal_binary_impl,
)
