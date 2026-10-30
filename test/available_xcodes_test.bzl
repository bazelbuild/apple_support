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

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(
    "@build_bazel_apple_support//xcode:available_xcodes.bzl",
    "available_xcodes",
)
load(
    "@build_bazel_apple_support//xcode:xcode_version.bzl",
    "xcode_version",
)
load(
    "@build_bazel_apple_support//xcode/private:providers.bzl",
    "AvailableXcodesInfo",
)  # buildifier: disable=bzl-visibility
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

def _versions_dict_merges_aliases(namer):
    available_xcodes(
        name = namer("my_xcodes"),
        default = namer(":xcode_8"),
        versions = {
            namer(":xcode_8"): ["8.0", "oldest"],
            namer(":xcode_9"): ["9.0", "latest"],
        },
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("xcode_8"),
        aliases = ["eight"],
        version = "8.0.0.8A1",
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("xcode_9"),
        version = "9.0.0.9A1",
        tags = FIXTURE_TAGS,
    )

    _versions_dict_merges_aliases_test(
        name = "versions_dict_merges_aliases",
        target_under_test = namer("my_xcodes"),
    )
    return ["versions_dict_merges_aliases"]

def _versions_dict_merges_aliases_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    info = target_under_test[AvailableXcodesInfo]

    asserts.equals(env, ["eight", "8.0", "oldest"], info.default_version.aliases)
    asserts.equals(env, 2, len(info.available_versions))
    asserts.equals(env, ["eight", "8.0", "oldest"], info.available_versions[0].aliases)
    asserts.equals(env, ["9.0", "latest"], info.available_versions[1].aliases)

    return analysistest.end(env)

_versions_dict_merges_aliases_test = analysistest.make(
    _versions_dict_merges_aliases_test_impl,
)

# ------------------------------------------------------------------------------

def available_xcodes_test(name):
    make_all_tests(
        name = name,
        tests = [
            _read_version_from_providers,
            _versions_dict_merges_aliases,
        ],
    )
