# Copyright 2024 The Bazel Authors. All rights reserved.
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

"""Tests for the `xcode_version` rule."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//xcode:xcode_version.bzl", "xcode_version")
load(
    "//xcode/private:providers.bzl",
    "XcodeVersionPropertiesInfo",
)  # buildifier: disable=bzl-visibility
load(":test_helpers.bzl", "FIXTURE_TAGS", "make_all_tests")

visibility("private")

# ------------------------------------------------------------------------------

def _read_version_from_providers(namer):
    xcode_version(
        name = namer("my_xcode"),
        default_ios_sdk_version = "9.0",
        default_macos_sdk_version = "9.3",
        default_tvos_sdk_version = "9.2",
        default_visionos_sdk_version = "9.4",
        default_watchos_sdk_version = "9.1",
        version = "8",
        tags = FIXTURE_TAGS,
    )

    _read_version_from_provider_test(
        name = "read_version_from_provider",
        target_under_test = namer("my_xcode"),
    )
    return ["read_version_from_provider"]

def _read_version_from_provider_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_properties = target_under_test[XcodeVersionPropertiesInfo]

    asserts.equals(env, "8", xcode_properties.xcode_version)
    asserts.equals(env, "9.0", xcode_properties.default_ios_sdk_version)
    asserts.equals(env, "9.1", xcode_properties.default_watchos_sdk_version)
    asserts.equals(env, "9.2", xcode_properties.default_tvos_sdk_version)
    asserts.equals(env, "9.3", xcode_properties.default_macos_sdk_version)
    asserts.equals(env, "9.4", xcode_properties.default_visionos_sdk_version)

    return analysistest.end(env)

_read_version_from_provider_test = analysistest.make(
    _read_version_from_provider_test_impl,
)

# ------------------------------------------------------------------------------

def xcode_version_test(name):
    make_all_tests(
        name = name,
        tests = [
            _read_version_from_providers,
        ] if bazel_features.apple.xcode_config_migrated else [],  # TODO: Remove once we test with Bazel 8+
    )
