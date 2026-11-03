# Copyright 2019 The Bazel Authors. All rights reserved.
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
"""Definition of a test rule to test xcode_support."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//lib:apple_support.bzl", "apple_support")
load("//lib:xcode_support.bzl", "xcode_support")

visibility("private")

# Template for the test script used to validate that the action outputs contain the expected
# values.
_TEST_SCRIPT_CONTENTS = """
#!/bin/bash

set -eu

if [[ "{past_version_is_true}" != "True" ]]; then
  echo "FAILURE: 'past_version_is_true' should be True, but it's {past_version_is_true}."
  exit 1
fi

if [[ "{future_version_is_false}" != "False" ]]; then
  echo "FAILURE: 'future_version_is_false' should be False, but it's {future_version_is_false}."
  exit 1
fi
"""

def _xcode_config(version):
    return apple_common.XcodeVersionConfig(
        ios_sdk_version = "1.0",
        ios_minimum_os_version = "1.0",
        watchos_sdk_version = "1.0",
        watchos_minimum_os_version = "1.0",
        tvos_sdk_version = "1.0",
        tvos_minimum_os_version = "1.0",
        macos_sdk_version = "1.0",
        macos_minimum_os_version = "1.0",
        visionos_sdk_version = "1.0",
        visionos_minimum_os_version = "1.0",
        xcode_version = version,
        availability = "UNKNOWN",
        xcode_version_flag = "",
        include_xcode_execution_info = False,
    )

def _xcode_support_test_impl(ctx):
    """Implementation of the xcode_support_test rule."""

    cases = [
        ("15.1", "15.0", True),
        ("15.1", "15.1", True),
        ("15.1", "16.0", False),
        ("/Applications/Xcode.app/Contents/Developer", "999", True),
    ] if bazel_features.apple.xcode_config_migrated else []
    for version, minimum, expected in cases:
        actual = xcode_support.is_xcode_at_least_version(_xcode_config(version), minimum)
        if actual != expected:
            fail("Expected Xcode %s >= %s to be %s, got %s" % (version, minimum, expected, actual))

    test_script = ctx.actions.declare_file("{}_test_script".format(ctx.label.name))
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    ctx.actions.write(test_script, _TEST_SCRIPT_CONTENTS.format(
        past_version_is_true = str(xcode_support.is_xcode_at_least_version(xcode_config, "1.0")),
        future_version_is_false = str(xcode_support.is_xcode_at_least_version(xcode_config, "999")),
    ), is_executable = True)

    return [DefaultInfo(executable = test_script)]

xcode_support_test = rule(
    implementation = _xcode_support_test_impl,
    attrs = apple_support.action_required_attrs(),
    test = True,
)

def _missing_xcode_version_impl(_ctx):
    xcode_support.is_xcode_at_least_version(_xcode_config(""), "15.0")
    return []

_missing_xcode_version = rule(implementation = _missing_xcode_version_impl)

def _missing_xcode_version_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "Could not determine Xcode version at all.")
    return analysistest.end(env)

_missing_xcode_version_test = analysistest.make(_missing_xcode_version_test_impl, expect_failure = True)

def missing_xcode_version_test(name):
    """Tests the missing version supported by the Starlark Xcode provider."""
    if bazel_features.apple.xcode_config_migrated:
        _missing_xcode_version(name = name + "_subject", tags = ["manual"])
        _missing_xcode_version_test(name = name, target_under_test = ":" + name + "_subject")
