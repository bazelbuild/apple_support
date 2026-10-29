# Copyright 2026 The Bazel Authors. All rights reserved.
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
"""Tests for the lipo command construction helpers."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:apple_support.bzl", "apple_support")
load("//lib:lipo.bzl", "lipo")

def _create_from_depset_test_impl(ctx):
    env = unittest.begin(ctx)
    inputs = [ctx.actions.declare_file("first binary"), ctx.actions.declare_file("second binary")]
    output = ctx.actions.declare_file("universal binary")
    for file in inputs + [output]:
        ctx.actions.write(file, "")
    calls = []
    actions = struct(run_shell = lambda **kwargs: calls.append(kwargs))
    for files in [inputs, depset(inputs)]:
        lipo.create(
            actions = actions,
            inputs = files,
            output = output,
            apple_platform_info = struct(platform = apple_common.platform.macos),
            xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
        )
    asserts.equals(env, 2, len(calls))
    asserts.equals(env, calls[0]["command"], calls[1]["command"])
    asserts.equals(env, inputs, calls[1]["inputs"])
    for file in inputs + [output]:
        asserts.true(env, "'" + file.path + "'" in calls[1]["command"])
    return unittest.end(env)

create_from_depset_test = unittest.make(
    _create_from_depset_test_impl,
    attrs = apple_support.action_required_attrs(),
)

def _extract_or_thin_test_impl(ctx):
    env = unittest.begin(ctx)
    input_file = ctx.actions.declare_file("input binary")
    output = ctx.actions.declare_file("extracted binary")
    for file in [input_file, output]:
        ctx.actions.write(file, "")
    calls = []
    actions = struct(run_shell = lambda **kwargs: calls.append(kwargs))
    for archs in [["arm64"], ["arm64", "x86_64"]]:
        for use_file in [True, False]:
            expression = "'" + input_file.path + "'" if use_file else '"$SDKROOT/input binary"'
            lipo.extract_or_thin(
                actions = actions,
                archs = archs,
                input_file = input_file if use_file else None,
                input_shell_expression = None if use_file else expression,
                output = output,
                apple_platform_info = struct(platform = apple_common.platform.macos),
                xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
            )
            call = calls[-1]
            flags = "-thin arm64" if len(archs) == 1 else "-extract arm64 -extract x86_64"
            asserts.equals(env, "mkdir -p '{}' && /usr/bin/lipo {} {} -output '{}'".format(
                output.dirname,
                expression,
                flags,
                output.path,
            ), call["command"])
            asserts.equals(env, [input_file] if use_file else [], call.get("inputs", []))
    asserts.equals(env, 4, len(calls))
    return unittest.end(env)

extract_or_thin_test = unittest.make(
    _extract_or_thin_test_impl,
    attrs = apple_support.action_required_attrs(),
)
