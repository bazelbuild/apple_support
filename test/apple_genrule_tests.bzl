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

"""Tests that apple_genrule configures actions for their execution platform."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//rules:apple_genrule.bzl", "apple_genrule")
load("//xcode:xcode_config.bzl", "xcode_config")
load("//xcode:xcode_version.bzl", "xcode_version")
load(":test_helpers.bzl", "FIXTURE_TAGS", "find_action")

def _apple_genrule_platform_test_impl(ctx):
    env = analysistest.begin(ctx)
    action = find_action(env, "Genrule")
    if not action:
        return analysistest.end(env)

    for variable in [
        "APPLE_SDK_PLATFORM",
        "APPLE_SDK_VERSION_OVERRIDE",
        "XCODE_VERSION_OVERRIDE",
    ]:
        asserts.equals(env, ctx.attr.macos_execution, variable in action.env, variable)

    return analysistest.end(env)

def _make_platform_test(target_platform):
    return analysistest.make(
        _apple_genrule_platform_test_impl,
        attrs = {
            "macos_execution": attr.bool(),
        },
        config_settings = {
            "//command_line_option:platforms": str(Label(target_platform)),
            "//command_line_option:extra_execution_platforms": [
                str(Label("//test:apple_genrule_linux_platform")),
                str(Label("//test:apple_genrule_macos_platform")),
            ],
            "//command_line_option:xcode_version_config": str(Label("//test:apple_genrule_xcode_config")),
            str(Label("//xcode:starlark_version_config")): str(Label("//test:apple_genrule_xcode_config")),
        },
    )

_linux_target_test = _make_platform_test("//test:apple_genrule_linux_platform")
_macos_target_test = _make_platform_test("//platforms:darwin_arm64")

def apple_genrule_test_suite(name):
    """Tests Linux and macOS execution independently of the target platform.

    Args:
        name: The name of the test suite.
    """
    xcode_version(
        name = "apple_genrule_xcode_version",
        version = "16.0",
        tags = FIXTURE_TAGS,
    )
    xcode_config(
        name = "apple_genrule_xcode_config",
        default = ":apple_genrule_xcode_version",
        versions = [":apple_genrule_xcode_version"],
        tags = FIXTURE_TAGS,
    )
    tests = []
    for execution_os in ["linux", "macos"]:
        native.platform(
            name = "apple_genrule_" + execution_os + "_platform",
            constraint_values = [
                "@platforms//cpu:arm64",
                "@platforms//os:" + execution_os,
            ],
        )
        fixture_name = name + "_" + execution_os
        apple_genrule(
            name = fixture_name,
            srcs = ["main.c"],
            outs = [fixture_name + ".txt"],
            cmd = "cat $(SRCS) > $@",
            exec_compatible_with = ["@platforms//os:" + execution_os],
            tags = FIXTURE_TAGS,
        )
        for target_os, test_rule in [
            ("linux", _linux_target_test),
            ("macos", _macos_target_test),
        ]:
            test_name = fixture_name + "_target_" + target_os + "_test"
            test_rule(
                name = test_name,
                target_under_test = ":" + fixture_name,
                macos_execution = execution_os == "macos",
            )
            tests.append(test_name)

    # These commands need Xcode even when Linux is the preferred execution
    # platform. Check the actual crosstool actions, not only their consumers.
    for tool, target in [
        ("wrapped_clang", "//crosstool:exec_wrapped_clang.target_config"),
        ("modulemap", "//crosstool:generate_layering_check_modulemap"),
    ]:
        test_name = name + "_" + tool + "_linux_first_test"
        _macos_target_test(
            name = test_name,
            target_under_test = target,
            macos_execution = True,
        )
        tests.append(test_name)

    native.test_suite(name = name, tests = tests)
