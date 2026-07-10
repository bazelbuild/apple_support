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

"""Tests for the `selected_xcode_version_retriever` rule."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(
    "@build_bazel_apple_support//xcode:selected_xcode_version_retriever.bzl",
    "selected_xcode_version_retriever",
)
load(
    "@build_bazel_apple_support//xcode:xcode_config.bzl",
    "xcode_config",
)
load(
    "@build_bazel_apple_support//xcode:xcode_version.bzl",
    "xcode_version",
)
load(":test_helpers.bzl", "FIXTURE_TAGS", "make_all_tests")

visibility("private")

# ------------------------------------------------------------------------------

def _retriever_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    flag_info = target_under_test[config_common.FeatureFlagInfo]
    asserts.equals(env, ctx.attr.expected_value, flag_info.value)

    return analysistest.end(env)

_retriever_standard_test = analysistest.make(
    _retriever_test_impl,
    attrs = {
        "expected_value": attr.string(mandatory = True),
    },
    config_settings = {
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:selected_xcode_retriever_test__standard_config",
    },
)

_retriever_padding_test = analysistest.make(
    _retriever_test_impl,
    attrs = {
        "expected_value": attr.string(mandatory = True),
    },
    config_settings = {
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:selected_xcode_retriever_test__padding_config",
    },
)

# ------------------------------------------------------------------------------

def _test_precisions_standard(namer):
    # Test version and config fixtures with a full version number.
    xcode_version(
        name = "selected_xcode_retriever_test__standard_xcode",
        version = "26.4.1.17E202",
        tags = FIXTURE_TAGS,
    )
    xcode_config(
        name = "selected_xcode_retriever_test__standard_config",
        default = ":selected_xcode_retriever_test__standard_xcode",
        versions = [":selected_xcode_retriever_test__standard_xcode"],
        tags = FIXTURE_TAGS,
    )

    # Major precision, should trim to 26.
    selected_xcode_version_retriever(
        name = namer("major_retriever"),
        precision = "major",
        tags = FIXTURE_TAGS,
    )
    _retriever_standard_test(
        name = "precision_major",
        target_under_test = namer("major_retriever"),
        expected_value = "26",
    )

    # Minor precision, should trim to 26.4.
    selected_xcode_version_retriever(
        name = namer("minor_retriever"),
        precision = "minor",
        tags = FIXTURE_TAGS,
    )
    _retriever_standard_test(
        name = "precision_minor",
        target_under_test = namer("minor_retriever"),
        expected_value = "26.4",
    )

    # Patch precision, should trim to 26.4.1.
    selected_xcode_version_retriever(
        name = namer("patch_retriever"),
        precision = "patch",
        tags = FIXTURE_TAGS,
    )
    _retriever_standard_test(
        name = "precision_patch",
        target_under_test = namer("patch_retriever"),
        expected_value = "26.4.1",
    )

    # Exact precision, should match the original version number exactly.
    selected_xcode_version_retriever(
        name = namer("exact_retriever"),
        precision = "exact",
        tags = FIXTURE_TAGS,
    )
    _retriever_standard_test(
        name = "precision_exact",
        target_under_test = namer("exact_retriever"),
        expected_value = "26.4.1.17E202",
    )

    return [
        "precision_major",
        "precision_minor",
        "precision_patch",
        "precision_exact",
    ]

def _test_precisions_padding(namer):
    # Test version and config fixtures with a short version number.
    xcode_version(
        name = "selected_xcode_retriever_test__padding_xcode",
        version = "26",
        tags = FIXTURE_TAGS,
    )
    xcode_config(
        name = "selected_xcode_retriever_test__padding_config",
        default = ":selected_xcode_retriever_test__padding_xcode",
        versions = [":selected_xcode_retriever_test__padding_xcode"],
        tags = FIXTURE_TAGS,
    )

    # Minor precision, should pad to 26.0.
    selected_xcode_version_retriever(
        name = namer("minor_pad_retriever"),
        precision = "minor",
        tags = FIXTURE_TAGS,
    )
    _retriever_padding_test(
        name = "precision_minor_padded",
        target_under_test = namer("minor_pad_retriever"),
        expected_value = "26.0",
    )

    # Patch precision, should pad to 26.0.0.
    selected_xcode_version_retriever(
        name = namer("patch_pad_retriever"),
        precision = "patch",
        tags = FIXTURE_TAGS,
    )
    _retriever_padding_test(
        name = "precision_patch_padded",
        target_under_test = namer("patch_pad_retriever"),
        expected_value = "26.0.0",
    )

    return [
        "precision_minor_padded",
        "precision_patch_padded",
    ]

# ------------------------------------------------------------------------------

def selected_xcode_version_retriever_test(name):
    make_all_tests(
        name = name,
        tests = [
            _test_precisions_standard,
            _test_precisions_padding,
        ],
    )
