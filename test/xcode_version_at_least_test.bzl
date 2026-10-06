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

"""Tests for the `xcode_version_at_least` macro and rule."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(
    "@build_bazel_apple_support//xcode:xcode_config.bzl",
    "xcode_config",
)
load(
    "@build_bazel_apple_support//xcode:xcode_version.bzl",
    "xcode_version",
)
load(
    "@build_bazel_apple_support//xcode:xcode_version_at_least.bzl",
    "xcode_version_at_least",
)
load(":test_helpers.bzl", "FIXTURE_TAGS", "make_all_tests")

visibility("private")

# ------------------------------------------------------------------------------

_SelectValueInfo = provider(
    doc = "Holds the value resolved by a `select()` expression under test.",
    fields = {
        "selected_value": "The string value resolved by `select()`.",
    },
)

def _select_holder_impl(ctx):
    return [_SelectValueInfo(selected_value = ctx.attr.selected_value)]

_select_holder = rule(
    implementation = _select_holder_impl,
    attrs = {
        "selected_value": attr.string(mandatory = True),
    },
)

def _select_value_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    asserts.equals(
        env,
        ctx.attr.expected_value,
        target_under_test[_SelectValueInfo].selected_value,
    )

    return analysistest.end(env)

def _make_xcode_select_test(xcode_version_str, config_name = "xcode_version_at_least_test__multi_config"):
    return analysistest.make(
        _select_value_test_impl,
        attrs = {
            "expected_value": attr.string(mandatory = True),
        },
        config_settings = {
            "//command_line_option:xcode_version": xcode_version_str,
            "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:" + config_name,
        },
    )

_select_xcode_26_0_test = _make_xcode_select_test("26.0.0.17A100")
_select_xcode_26_2_test = _make_xcode_select_test("26.2.0.17C52")
_select_xcode_26_4_0_test = _make_xcode_select_test("26.4.0.17E192")
_select_xcode_26_4_1_test = _make_xcode_select_test("26.4.1.17E202")
_select_xcode_27_0_beta_test = _make_xcode_select_test("27.0.0.27A5228h")
_select_xcode_padded_26_test = _make_xcode_select_test("26")

# ------------------------------------------------------------------------------

def _setup_shared_xcode_config():
    xcode_version(
        name = "xcode_version_at_least_test__xcode_26_0",
        version = "26.0.0.17A100",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = "xcode_version_at_least_test__xcode_26_2",
        version = "26.2.0.17C52",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = "xcode_version_at_least_test__xcode_26_4_0",
        version = "26.4.0.17E192",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = "xcode_version_at_least_test__xcode_26_4_1",
        version = "26.4.1.17E202",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = "xcode_version_at_least_test__xcode_27_0_beta",
        version = "27.0.0.27A5228h",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = "xcode_version_at_least_test__xcode_padded_26",
        version = "26",
        tags = FIXTURE_TAGS,
    )
    xcode_config(
        name = "xcode_version_at_least_test__multi_config",
        default = ":xcode_version_at_least_test__xcode_26_4_1",
        versions = [
            ":xcode_version_at_least_test__xcode_26_0",
            ":xcode_version_at_least_test__xcode_26_2",
            ":xcode_version_at_least_test__xcode_26_4_0",
            ":xcode_version_at_least_test__xcode_26_4_1",
            ":xcode_version_at_least_test__xcode_27_0_beta",
            ":xcode_version_at_least_test__xcode_padded_26",
        ],
        tags = FIXTURE_TAGS,
    )

def _test_single_threshold(namer):
    _setup_shared_xcode_config()

    xcode_version_at_least(
        name = namer("at_least_26_4"),
        minimum_xcode_version = "26.4",
        tags = FIXTURE_TAGS,
    )
    _select_holder(
        name = namer("single_holder"),
        selected_value = select({
            namer(":at_least_26_4"): "matched",
            "//conditions:default": "default",
        }),
        tags = FIXTURE_TAGS,
    )

    _select_xcode_26_2_test(
        name = "single_threshold_below",
        target_under_test = namer(":single_holder"),
        expected_value = "default",
    )
    _select_xcode_26_4_0_test(
        name = "single_threshold_equal",
        target_under_test = namer(":single_holder"),
        expected_value = "matched",
    )
    _select_xcode_26_4_1_test(
        name = "single_threshold_above_patch",
        target_under_test = namer(":single_holder"),
        expected_value = "matched",
    )
    _select_xcode_27_0_beta_test(
        name = "single_threshold_above_major_beta",
        target_under_test = namer(":single_holder"),
        expected_value = "matched",
    )

    return [
        "single_threshold_below",
        "single_threshold_equal",
        "single_threshold_above_patch",
        "single_threshold_above_major_beta",
    ]

def _test_precisions_and_build_numbers(namer):
    cases = [
        ("major_match", "26", "matched"),
        ("major_nomatch", "27", "default"),
        ("minor_match", "26.4", "matched"),
        ("minor_nomatch", "26.5", "default"),
        ("patch_match", "26.4.1", "matched"),
        ("patch_nomatch", "26.4.2", "default"),
        ("build_lower_match", "26.4.1.17E192", "matched"),
        ("build_equal_match", "26.4.1.17E202", "matched"),
        ("build_higher_nomatch", "26.4.1.17E300", "default"),
    ]

    test_names = []
    for suffix, min_ver, expected in cases:
        setting_name = namer("setting_" + suffix)
        holder_name = namer("holder_" + suffix)
        test_name = "precision_" + suffix

        xcode_version_at_least(
            name = setting_name,
            minimum_xcode_version = min_ver,
            tags = FIXTURE_TAGS,
        )
        _select_holder(
            name = holder_name,
            selected_value = select({
                ":" + setting_name: "matched",
                "//conditions:default": "default",
            }),
            tags = FIXTURE_TAGS,
        )
        _select_xcode_26_4_1_test(
            name = test_name,
            target_under_test = ":" + holder_name,
            expected_value = expected,
        )
        test_names.append(test_name)

    return test_names

def _test_padded_versions(namer):
    xcode_version_at_least(
        name = namer("at_least_26_0_0"),
        minimum_xcode_version = "26.0.0",
        tags = FIXTURE_TAGS,
    )
    _select_holder(
        name = namer("holder_26_0_0"),
        selected_value = select({
            namer(":at_least_26_0_0"): "matched",
            "//conditions:default": "default",
        }),
        tags = FIXTURE_TAGS,
    )

    _select_xcode_padded_26_test(
        name = "single_component_xcode_matches_three_component_minimum_xcode_version",
        target_under_test = namer(":holder_26_0_0"),
        expected_value = "matched",
    )

    return [
        "single_component_xcode_matches_three_component_minimum_xcode_version",
    ]

def _test_chained_select_refinement(namer):
    xcode_version_at_least(
        name = namer("chain_26_2"),
        minimum_xcode_version = "26.2",
        tags = FIXTURE_TAGS,
    )
    xcode_version_at_least(
        name = namer("chain_26_4"),
        after = [namer(":chain_26_2")],
        minimum_xcode_version = "26.4",
        tags = FIXTURE_TAGS,
    )
    xcode_version_at_least(
        name = namer("chain_27_0"),
        after = [namer(":chain_26_4")],
        minimum_xcode_version = "27.0",
        tags = FIXTURE_TAGS,
    )

    _select_holder(
        name = namer("chained_holder"),
        selected_value = select({
            namer(":chain_26_2"): "xcode_26_2_or_newer",
            namer(":chain_26_4"): "xcode_26_4_or_newer",
            namer(":chain_27_0"): "xcode_27_0_or_newer",
            "//conditions:default": "older_than_26_2",
        }),
        tags = FIXTURE_TAGS,
    )

    _select_xcode_26_0_test(
        name = "chained_select_below_all",
        target_under_test = namer(":chained_holder"),
        expected_value = "older_than_26_2",
    )
    _select_xcode_26_2_test(
        name = "chained_select_matches_first",
        target_under_test = namer(":chained_holder"),
        expected_value = "xcode_26_2_or_newer",
    )
    _select_xcode_26_4_1_test(
        name = "chained_select_matches_second",
        target_under_test = namer(":chained_holder"),
        expected_value = "xcode_26_4_or_newer",
    )
    _select_xcode_27_0_beta_test(
        name = "chained_select_matches_third_transitively",
        target_under_test = namer(":chained_holder"),
        expected_value = "xcode_27_0_or_newer",
    )

    return [
        "chained_select_below_all",
        "chained_select_matches_first",
        "chained_select_matches_second",
        "chained_select_matches_third_transitively",
    ]

def _test_qualified_labels_in_after(namer):
    xcode_version_at_least(
        name = namer("qual_26_2"),
        minimum_xcode_version = "26.2",
        tags = FIXTURE_TAGS,
    )
    xcode_version_at_least(
        name = namer("qual_26_4"),
        after = [
            "@build_bazel_apple_support//test:" + namer("qual_26_2"),
        ],
        minimum_xcode_version = "26.4",
        tags = FIXTURE_TAGS,
    )
    _select_holder(
        name = namer("qual_holder"),
        selected_value = select({
            namer(":qual_26_2"): "xcode_26_2_or_newer",
            namer(":qual_26_4"): "xcode_26_4_or_newer",
            "//conditions:default": "older_than_26_2",
        }),
        tags = FIXTURE_TAGS,
    )

    _select_xcode_26_4_1_test(
        name = "qualified_labels_in_after_matches_refined",
        target_under_test = namer(":qual_holder"),
        expected_value = "xcode_26_4_or_newer",
    )

    return ["qualified_labels_in_after_matches_refined"]

def _expect_failure_message_test_impl(ctx):
    env = analysistest.begin(ctx)
    for expected_substring in ctx.attr.expected_messages:
        asserts.expect_failure(env, expected_substring)
    return analysistest.end(env)

_expect_failure_message_test = analysistest.make(
    _expect_failure_message_test_impl,
    attrs = {
        "expected_messages": attr.string_list(mandatory = True),
    },
    config_settings = {
        "//command_line_option:xcode_version": "26.4.1.17E202",
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:xcode_version_at_least_test__multi_config",
    },
    expect_failure = True,
)

def _test_after_conflicts(namer):
    xcode_version_at_least(
        name = namer("conflict_base_26_4"),
        minimum_xcode_version = "26.4",
        tags = FIXTURE_TAGS,
    )
    xcode_version_at_least(
        name = namer("conflict_lower_26_2"),
        after = [namer(":conflict_base_26_4")],
        minimum_xcode_version = "26.2",
        tags = FIXTURE_TAGS,
    )
    xcode_version_at_least(
        name = namer("conflict_equal_26_4_0"),
        after = [namer(":conflict_base_26_4")],
        minimum_xcode_version = "26.4.0",
        tags = FIXTURE_TAGS,
    )

    # Declare `out_of_order_27_0` before `out_of_order_26_4` so `native.existing_rule`
    # cannot see `out_of_order_26_4`'s transitive `after` dependency on `out_of_order_26_2`.
    xcode_version_at_least(
        name = namer("out_of_order_27_0"),
        after = [namer(":out_of_order_26_4")],
        minimum_xcode_version = "27.0",
        tags = FIXTURE_TAGS,
    )
    xcode_version_at_least(
        name = namer("out_of_order_26_2"),
        minimum_xcode_version = "26.2",
        tags = FIXTURE_TAGS,
    )
    xcode_version_at_least(
        name = namer("out_of_order_26_4"),
        after = [namer(":out_of_order_26_2")],
        minimum_xcode_version = "26.4",
        tags = FIXTURE_TAGS,
    )

    _expect_failure_message_test(
        name = "after_lower_than_referenced_version_fails",
        target_under_test = namer(":conflict_lower_26_2") + "_flag",
        expected_messages = [
            "has a lower minimum_xcode_version than",
            'Configure `after = ["' + namer(":conflict_lower_26_2") + '"]` on',
        ],
    )
    _expect_failure_message_test(
        name = "after_equal_to_referenced_version_fails",
        target_under_test = namer(":conflict_equal_26_4_0") + "_flag",
        expected_messages = [
            "specify equivalent minimum Xcode versions",
            "Use a single `xcode_version_at_least` target for this version, or configure distinct `minimum_xcode_version` values with `after` set on the higher-version target.",
        ],
    )
    _expect_failure_message_test(
        name = "after_declared_before_referenced_transitive_target_fails",
        target_under_test = namer(":out_of_order_27_0") + "_flag",
        expected_messages = [
            "is missing transitive `after` condition",
            "Declare lower-version `xcode_version_at_least` targets before higher-version targets in the BUILD file, or list all lower-version targets explicitly in `after`.",
        ],
    )

    return [
        "after_lower_than_referenced_version_fails",
        "after_equal_to_referenced_version_fails",
        "after_declared_before_referenced_transitive_target_fails",
    ]

# ------------------------------------------------------------------------------

def xcode_version_at_least_test(name):
    make_all_tests(
        name = name,
        tests = [
            _test_single_threshold,
            _test_precisions_and_build_numbers,
            _test_padded_versions,
            _test_chained_select_refinement,
            _test_qualified_labels_in_after,
            _test_after_conflicts,
        ],
    )
