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

"""Tests for the `available_xcodes` rule."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:unittest.bzl", "analysistest")
load("//xcode:available_xcodes.bzl", "available_xcodes")
load("//xcode:xcode_version.bzl", "xcode_version")
load(":test_helpers.bzl", "FIXTURE_TAGS", "make_all_tests")

visibility("private")

# ------------------------------------------------------------------------------

def _read_version_from_providers(namer):
    available_xcodes(
        name = namer("my_xcodes"),
        default = namer(":xcode_8"),
        versions = [
            namer(":xcode_8"),
            namer(":xcode_9"),
        ],
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("xcode_8"),
        default_ios_sdk_version = "9.0",
        default_macos_sdk_version = "9.3",
        default_tvos_sdk_version = "9.2",
        default_watchos_sdk_version = "9.1",
        version = "8",
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("xcode_9"),
        default_ios_sdk_version = "10.0",
        default_macos_sdk_version = "10.3",
        default_tvos_sdk_version = "10.2",
        default_watchos_sdk_version = "10.1",
        version = "9",
        tags = FIXTURE_TAGS,
    )

    _read_version_from_providers_test(
        name = "read_version_from_providers",
        target_under_test = namer("my_xcodes"),
    )
    return ["read_version_from_providers"]

def _read_version_from_providers_test_impl(ctx):
    env = analysistest.begin(ctx)

    # TODO: b/311385128 - Add tests for the provider contents once we've moved
    # the providers here. We can't test them yet because they are internal to
    # built-in Starlark.

    return analysistest.end(env)

_read_version_from_providers_test = analysistest.make(
    _read_version_from_providers_test_impl,
)

# ------------------------------------------------------------------------------

def available_xcodes_test(name):
    make_all_tests(
        name = name,
        tests = [
            _read_version_from_providers,
        ] if bazel_features.apple.xcode_config_migrated else [],  # TODO: Remove once we test with Bazel 8+
    )
