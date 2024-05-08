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

"""Tests for the `xcode_config` rule."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//xcode:available_xcodes.bzl", "available_xcodes")
load(
    "//xcode:xcode_config.bzl",
    "UNAVAILABLE_XCODE_MESSAGE",
    "xcode_config",
)
load("//xcode:xcode_version.bzl", "xcode_version")
load(
    "//xcode/private:providers.bzl",
    "XcodeVersionPropertiesInfo",
)  # buildifier: disable=bzl-visibility
load(
    ":test_helpers.bzl",
    "FIXTURE_TAGS",
    "assert_warning",
    "find_action",
    "make_all_tests",
)

visibility("private")

# ------------------------------------------------------------------------------

def _version_retriever_impl(ctx):
    xcode_properties = ctx.attr._xcode_dep[XcodeVersionPropertiesInfo]
    version = xcode_properties.xcode_version
    return [config_common.FeatureFlagInfo(value = version)]

version_retriever = rule(
    implementation = _version_retriever_impl,
    attrs = {
        "_xcode_dep": attr.label(
            default = configuration_field(
                fragment = "apple",
                name = "xcode_config_label",
            ),
        ),
    },
)

def _provider_grabber_impl(ctx):
    return [ctx.attr._xcode_dep[apple_common.XcodeVersionConfig]]

provider_grabber = rule(
    implementation = _provider_grabber_impl,
    attrs = {
        "_xcode_dep": attr.label(
            default = configuration_field(
                fragment = "apple",
                name = "xcode_config_label",
            ),
        ),
    },
    fragments = ["apple"],
)

def _provider_grabber_aspect_impl(_target, ctx):
    return [ctx.attr._xcode_dep[apple_common.XcodeVersionConfig]]

provider_grabber_aspect = aspect(
    implementation = _provider_grabber_aspect_impl,
    attrs = {
        "_xcode_dep": attr.label(
            default = configuration_field(
                fragment = "apple",
                name = "xcode_config_label",
            ),
        ),
    },
    fragments = ["apple"],
)

def _provider_grabber_with_aspect_impl(ctx):
    return [ctx.attr.deps[0][apple_common.XcodeVersionConfig]]

provider_grabber_with_aspect = rule(
    implementation = _provider_grabber_with_aspect_impl,
    attrs = {
        "deps": attr.label_list(
            mandatory = True,
            allow_files = True,
            aspects = [provider_grabber_aspect],
        ),
    },
    fragments = ["apple"],
)

# ------------------------------------------------------------------------------

def _mutual_and_explicit_xcodes_fails(namer):
    xcode_config(
        name = namer("foo"),
        default = namer(":version512"),
        local_versions = namer(":local"),
        remote_versions = namer(":remote"),
        versions = [
            namer(":version512"),
            namer(":version84"),
        ],
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version84"),
        version = "8.4",
        tags = FIXTURE_TAGS,
    )

    available_xcodes(
        name = namer("remote"),
        default = namer(":version512"),
        versions = [namer(":version512")],
        tags = FIXTURE_TAGS,
    )

    available_xcodes(
        name = namer("local"),
        default = namer(":version84"),
        versions = [namer(":version84")],
        tags = FIXTURE_TAGS,
    )

    _mutual_and_explicit_xcodes_fails_test(
        name = "mutual_and_explicit_xcodes_fails",
        target_under_test = namer("foo"),
    )
    return ["mutual_and_explicit_xcodes_fails"]

def _mutual_and_explicit_xcodes_fails_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "'versions' may not be set if '[local,remote]_versions' is set.")
    return analysistest.end(env)

_mutual_and_explicit_xcodes_fails_test = analysistest.make(
    _mutual_and_explicit_xcodes_fails_test_impl,
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _mutual_and_default_xcodes_fails(namer):
    xcode_config(
        name = namer("foo"),
        default = namer(":version512"),
        local_versions = namer(":local"),
        remote_versions = namer(":remote"),
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version84"),
        version = "8.4",
        tags = FIXTURE_TAGS,
    )

    available_xcodes(
        name = namer("remote"),
        default = namer(":version512"),
        versions = [namer(":version512")],
        tags = FIXTURE_TAGS,
    )

    available_xcodes(
        name = namer("local"),
        default = namer(":version84"),
        versions = [namer(":version84")],
        tags = FIXTURE_TAGS,
    )

    _mutual_and_default_xcodes_fails_test(
        name = "mutual_and_default_xcodes_fails",
        target_under_test = namer("foo"),
    )
    return ["mutual_and_default_xcodes_fails"]

def _mutual_and_default_xcodes_fails_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "'default' may not be set if '[local,remote]_versions' is set.")
    return analysistest.end(env)

_mutual_and_default_xcodes_fails_test = analysistest.make(
    _mutual_and_default_xcodes_fails_test_impl,
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _no_local_xcodes_fails(namer):
    xcode_config(
        name = namer("foo"),
        remote_versions = namer(":remote"),
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )

    available_xcodes(
        name = namer("remote"),
        default = namer(":version512"),
        versions = [namer(":version512")],
        tags = FIXTURE_TAGS,
    )

    _no_local_xcodes_fails_test(
        name = "no_local_xcodes_fails",
        target_under_test = namer("foo"),
    )
    return ["no_local_xcodes_fails"]

def _no_local_xcodes_fails_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "if 'remote_versions' are set, you must also set 'local_versions'")
    return analysistest.end(env)

_no_local_xcodes_fails_test = analysistest.make(
    _no_local_xcodes_fails_test_impl,
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _accepts_flag_for_mutually_available(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "accepts_flag_for_mutually_available__foo",
        remote_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
            struct(name = "version84", version = "8.4"),
        ],
        local_versions = [
            struct(name = "version84", version = "8.4", is_default = True),
        ],
    )

    _accepts_flag_for_mutually_available_test(
        name = "accepts_flag_for_mutually_available",
        target_under_test = "accepts_flag_for_mutually_available__foo",
    )
    return ["accepts_flag_for_mutually_available"]

def _accepts_flag_for_mutually_available_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "8.4", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "both", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_accepts_flag_for_mutually_available_test = analysistest.make(
    _accepts_flag_for_mutually_available_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "8.4",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:accepts_flag_for_mutually_available__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _prefers_flag_over_mutually_available(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "prefers_flag_over_mutually_available__foo",
        remote_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
            struct(name = "version84", version = "8.4"),
        ],
        local_versions = [
            struct(name = "version84", version = "8.4", is_default = True),
        ],
    )

    _prefers_flag_over_mutually_available_test(
        name = "prefers_flag_over_mutually_available",
        target_under_test = "prefers_flag_over_mutually_available__foo",
    )
    return ["prefers_flag_over_mutually_available"]

def _prefers_flag_over_mutually_available_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "remote", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-local" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    assert_warning(
        env,
        "version_not_available_locally",
        "command={};local_versions=8.4;version=5.1.2".format(UNAVAILABLE_XCODE_MESSAGE),
    )

    return analysistest.end(env)

_prefers_flag_over_mutually_available_test = analysistest.make(
    _prefers_flag_over_mutually_available_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "5.1.2",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:prefers_flag_over_mutually_available__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _warn_with_explicit_local_only_version(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "warn_with_explicit_local_only_version__foo",
        remote_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
        ],
        local_versions = [
            struct(name = "version84", version = "8.4", is_default = True),
        ],
    )

    _warn_with_explicit_local_only_version_test(
        name = "warn_with_explicit_local_only_version",
        target_under_test = "warn_with_explicit_local_only_version__foo",
    )
    return ["warn_with_explicit_local_only_version"]

def _warn_with_explicit_local_only_version_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "8.4", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-remote" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    assert_warning(
        env,
        "explicit_version_not_available_remotely",
        "version=8.4",
    )

    return analysistest.end(env)

_warn_with_explicit_local_only_version_test = analysistest.make(
    _warn_with_explicit_local_only_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "8.4",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:warn_with_explicit_local_only_version__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _prefer_local_default_if_no_mutual_no_flag_different_main_version(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "prefer_local_default_if_no_mutual_no_flag_different_main_version__foo",
        remote_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
        ],
        local_versions = [
            struct(name = "version84", version = "8.4", is_default = True),
        ],
    )

    _prefer_local_default_if_no_mutual_no_flag_different_main_version_test(
        name = "prefer_local_default_if_no_mutual_no_flag_different_main_version",
        target_under_test = "prefer_local_default_if_no_mutual_no_flag_different_main_version__foo",
    )
    return ["prefer_local_default_if_no_mutual_no_flag_different_main_version"]

def _prefer_local_default_if_no_mutual_no_flag_different_main_version_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "8.4", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-remote" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    assert_warning(
        env,
        "local_default_not_available_remotely",
        "local_version=8.4;remote_versions=5.1.2",
    )

    return analysistest.end(env)

_prefer_local_default_if_no_mutual_no_flag_different_main_version_test = analysistest.make(
    _prefer_local_default_if_no_mutual_no_flag_different_main_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:prefer_local_default_if_no_mutual_no_flag_different_main_version__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _prefer_local_default_if_no_mutual_no_flag_different_build_alias(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "prefer_local_default_if_no_mutual_no_flag_different_build_alias__foo",
        remote_versions = [
            struct(name = "version10", version = "10.0", is_default = True, aliases = ["10.0.0.101ff", "10.0"]),
        ],
        local_versions = [
            struct(name = "version10.0.0.10C504", version = "10.0.0.10C504", is_default = True, aliases = ["10.0.0.10C504", "10.0"]),
        ],
    )

    _prefer_local_default_if_no_mutual_no_flag_different_build_alias_test(
        name = "prefer_local_default_if_no_mutual_no_flag_different_build_alias",
        target_under_test = "prefer_local_default_if_no_mutual_no_flag_different_build_alias__foo",
    )
    return ["prefer_local_default_if_no_mutual_no_flag_different_build_alias"]

def _prefer_local_default_if_no_mutual_no_flag_different_build_alias_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "10.0.0.10C504", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-remote" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    assert_warning(
        env,
        "local_default_not_available_remotely",
        "local_version=10.0.0.10C504;remote_versions=10.0",
    )

    return analysistest.end(env)

_prefer_local_default_if_no_mutual_no_flag_different_build_alias_test = analysistest.make(
    _prefer_local_default_if_no_mutual_no_flag_different_build_alias_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:prefer_local_default_if_no_mutual_no_flag_different_build_alias__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _prefer_local_default_if_no_mutual_no_flag_different_full_version(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "prefer_local_default_if_no_mutual_no_flag_different_full_version__foo",
        remote_versions = [
            struct(name = "version10", version = "10.0.0.101ff", is_default = True, aliases = ["10.0", "10.0.0.101ff"]),
        ],
        local_versions = [
            struct(name = "version10.0.0.10C504", version = "10.0.0.10C504", is_default = True, aliases = ["10.0.0.10C504", "10.0"]),
        ],
    )

    _prefer_local_default_if_no_mutual_no_flag_different_full_version_test(
        name = "prefer_local_default_if_no_mutual_no_flag_different_full_version",
        target_under_test = "prefer_local_default_if_no_mutual_no_flag_different_full_version__foo",
    )
    return ["prefer_local_default_if_no_mutual_no_flag_different_full_version"]

def _prefer_local_default_if_no_mutual_no_flag_different_full_version_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "10.0.0.10C504", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-remote" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    assert_warning(
        env,
        "local_default_not_available_remotely",
        "local_version=10.0.0.10C504;remote_versions=10.0.0.101ff",
    )

    return analysistest.end(env)

_prefer_local_default_if_no_mutual_no_flag_different_full_version_test = analysistest.make(
    _prefer_local_default_if_no_mutual_no_flag_different_full_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:prefer_local_default_if_no_mutual_no_flag_different_full_version__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _choose_newest_mutual_xcode(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "choose_newest_mutual_xcode__foo",
        remote_versions = [
            struct(name = "version92", version = "9.2", is_default = True),
            struct(name = "version10", version = "10", aliases = ["10.0.0.10C504"]),
            struct(name = "version84", version = "8.4"),
        ],
        local_versions = [
            struct(name = "version9", version = "9", is_default = True),
            struct(name = "version84", version = "8.4"),
            struct(name = "version10.0.0.10C504", version = "10.0.0.10C504", aliases = ["10.0"]),
        ],
    )

    _choose_newest_mutual_xcode_test(
        name = "choose_newest_mutual_xcode",
        target_under_test = "choose_newest_mutual_xcode__foo",
    )
    return ["choose_newest_mutual_xcode"]

def _choose_newest_mutual_xcode_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "10", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "both", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_choose_newest_mutual_xcode_test = analysistest.make(
    _choose_newest_mutual_xcode_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:choose_newest_mutual_xcode__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _invalid_xcode_from_mutual_throws(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "invalid_xcode_from_mutual_throws__foo",
        remote_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
            struct(name = "version84", version = "8.4"),
        ],
        local_versions = [
            struct(name = "version84", version = "8.4", is_default = True),
        ],
    )

    _invalid_xcode_from_mutual_throws_test(
        name = "invalid_xcode_from_mutual_throws",
        target_under_test = "invalid_xcode_from_mutual_throws__foo",
    )
    return ["invalid_xcode_from_mutual_throws"]

def _invalid_xcode_from_mutual_throws_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "--xcode_version=6 specified, but '6' is not an available Xcode version. Locally available versions: [8.4]. Remotely available versions: [5.1.2, 8.4].")
    return analysistest.end(env)

_invalid_xcode_from_mutual_throws_test = analysistest.make(
    _invalid_xcode_from_mutual_throws_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "6",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:invalid_xcode_from_mutual_throws__foo",
        )),
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _apple_common_xcode_version_config_constructor_fails_on_bad_input(namer):
    _apple_common_xcode_version_config_fails_on_bad_input_rule(
        name = namer("test"),
        tags = FIXTURE_TAGS,
    )

    _apple_common_xcode_version_config_constructor_fails_on_bad_input_test(
        name = "apple_common_xcode_version_config_constructor_fails_on_bad_input",
        target_under_test = namer("test"),
    )
    return ["apple_common_xcode_version_config_constructor_fails_on_bad_input"]

def _apple_common_xcode_version_config_fails_on_bad_input_rule_impl(_ctx):
    return [
        apple_common.XcodeVersionConfig(
            ios_sdk_version = "not a valid dotted version",
            ios_minimum_os_version = "1.2",
            watchos_sdk_version = "1.3",
            watchos_minimum_os_version = "1.4",
            tvos_sdk_version = "1.5",
            tvos_minimum_os_version = "1.6",
            macos_sdk_version = "1.7",
            macos_minimum_os_version = "1.8",
            visionos_sdk_version = "1.9",
            visionos_minimum_os_version = "1.10",
            xcode_version = "1.11",
            availability = "UNKNOWN",
            xcode_version_flag = "0.0",
            include_xcode_execution_info = False,
        ),
    ]

_apple_common_xcode_version_config_fails_on_bad_input_rule = rule(
    _apple_common_xcode_version_config_fails_on_bad_input_rule_impl,
)

def _apple_common_xcode_version_config_constructor_fails_on_bad_input_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "Dotted version components must all start with the form")
    asserts.expect_failure(env, "got 'not a valid dotted version'")
    return analysistest.end(env)

_apple_common_xcode_version_config_constructor_fails_on_bad_input_test = analysistest.make(
    _apple_common_xcode_version_config_constructor_fails_on_bad_input_test_impl,
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _apple_common_xcode_version_config_constructor(namer):
    _apple_common_xcode_version_config_rule(
        name = namer("test"),
        tags = FIXTURE_TAGS,
    )

    _apple_common_xcode_version_config_constructor_test(
        name = "apple_common_xcode_version_config_constructor",
        target_under_test = namer("test"),
    )
    return ["apple_common_xcode_version_config_constructor"]

def _apple_common_xcode_version_config_rule_impl(_ctx):
    return [
        apple_common.XcodeVersionConfig(
            ios_sdk_version = "1.1",
            ios_minimum_os_version = "1.2",
            watchos_sdk_version = "1.3",
            watchos_minimum_os_version = "1.4",
            tvos_sdk_version = "1.5",
            tvos_minimum_os_version = "1.6",
            macos_sdk_version = "1.7",
            macos_minimum_os_version = "1.8",
            visionos_sdk_version = "1.9",
            visionos_minimum_os_version = "1.10",
            xcode_version = "1.11",
            availability = "UNKNOWN",
            xcode_version_flag = "0.0",
            include_xcode_execution_info = False,
        ),
    ]

_apple_common_xcode_version_config_rule = rule(
    _apple_common_xcode_version_config_rule_impl,
)

def _apple_common_xcode_version_config_constructor_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "1.1", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.ios_device)))
    asserts.equals(env, "1.1", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.ios_simulator)))
    asserts.equals(env, "1.2", str(xcode_version_info.minimum_os_for_platform_type(apple_common.platform_type.ios)))
    asserts.equals(env, "1.2", str(xcode_version_info.minimum_os_for_platform_type(apple_common.platform_type.catalyst)))
    asserts.equals(env, "1.3", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.watchos_device)))
    asserts.equals(env, "1.3", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.watchos_simulator)))
    asserts.equals(env, "1.4", str(xcode_version_info.minimum_os_for_platform_type(apple_common.platform_type.watchos)))
    asserts.equals(env, "1.5", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.tvos_device)))
    asserts.equals(env, "1.5", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.tvos_simulator)))
    asserts.equals(env, "1.6", str(xcode_version_info.minimum_os_for_platform_type(apple_common.platform_type.tvos)))
    asserts.equals(env, "1.7", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.macos)))
    asserts.equals(env, "1.7", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.catalyst)))
    asserts.equals(env, "1.8", str(xcode_version_info.minimum_os_for_platform_type(apple_common.platform_type.macos)))
    asserts.equals(env, "1.9", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.visionos_device)))
    asserts.equals(env, "1.9", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.visionos_simulator)))
    asserts.equals(env, "1.10", str(xcode_version_info.minimum_os_for_platform_type(apple_common.platform_type.visionos)))
    asserts.equals(env, "1.11", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.equals(env, {
        "requires-darwin": "",
        "supports-xcode-requirements-set": "",
    }, xcode_version_info.execution_info())

    return analysistest.end(env)

_apple_common_xcode_version_config_constructor_test = analysistest.make(
    _apple_common_xcode_version_config_constructor_test_impl,
)

# ------------------------------------------------------------------------------

def _config_alias_config_setting(namer):
    version_retriever(
        name = namer("flag_propagator"),
        tags = FIXTURE_TAGS,
    )

    xcode_config(
        name = "config_alias_config_setting__config",
        default = namer(":version512"),
        versions = [
            namer(":version512"),
            namer(":version64"),
            namer(":version12"),
        ],
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version64"),
        aliases = [
            "6.0",
            "six",
            "6",
        ],
        version = "6.4",
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version12"),
        version = "12",
        tags = FIXTURE_TAGS,
    )

    native.config_setting(
        name = namer("xcode_5_1_2"),
        flag_values = {namer(":flag_propagator"): "5.1.2"},
    )

    native.config_setting(
        name = namer("xcode_6_4"),
        flag_values = {namer(":flag_propagator"): "6.4"},
    )

    native.genrule(
        name = namer("gen"),
        srcs = [],
        outs = [namer("out")],
        cmd = select({
            namer(":xcode_5_1_2"): "5.1.2",
            namer(":xcode_6_4"): "6.4",
            "//conditions:default": "none",
        }),
        tags = FIXTURE_TAGS,
    )

    _config_alias_config_setting_no_flag_test(
        name = "config_alias_config_setting_no_flag",
        target_under_test = namer("gen"),
    )
    _config_alias_config_setting_6_4_test(
        name = "config_alias_config_setting_6_4",
        target_under_test = namer("gen"),
    )
    _config_alias_config_setting_6_test(
        name = "config_alias_config_setting_6",
        target_under_test = namer("gen"),
    )
    _config_alias_config_setting_12_test(
        name = "config_alias_config_setting_12",
        target_under_test = namer("gen"),
    )
    return [
        "config_alias_config_setting_no_flag",
        "config_alias_config_setting_6_4",
        "config_alias_config_setting_6",
        "config_alias_config_setting_12",
    ]

def _config_alias_config_setting_no_flag_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.true(env, find_action(env, "Genrule").argv[-1].endswith("5.1.2"))
    return analysistest.end(env)

_config_alias_config_setting_no_flag_test = analysistest.make(
    _config_alias_config_setting_no_flag_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:config_alias_config_setting__config",
        )),
    },
)

def _config_alias_config_setting_6_4_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.true(env, find_action(env, "Genrule").argv[-1].endswith("6.4"))
    return analysistest.end(env)

_config_alias_config_setting_6_4_test = analysistest.make(
    _config_alias_config_setting_6_4_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:config_alias_config_setting__config",
        )),
        "//command_line_option:xcode_version": "6.4",
    },
)

_config_alias_config_setting_6_test = analysistest.make(
    _config_alias_config_setting_6_4_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:config_alias_config_setting__config",
        )),
        "//command_line_option:xcode_version": "6",
    },
)

def _config_alias_config_setting_12_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.true(env, find_action(env, "Genrule").argv[-1].endswith("none"))
    return analysistest.end(env)

_config_alias_config_setting_12_test = analysistest.make(
    _config_alias_config_setting_12_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:config_alias_config_setting__config",
        )),
        "//command_line_option:xcode_version": "12",
    },
)

# ------------------------------------------------------------------------------

def _default_version_config_setting(namer):
    version_retriever(
        name = namer("flag_propagator"),
        tags = FIXTURE_TAGS,
    )

    xcode_config(
        name = "default_version_config_setting__foo",
        default = namer(":version512"),
        versions = [
            namer(":version512"),
            namer(":version64"),
        ],
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version64"),
        aliases = [
            "6.0",
            "foo",
            "6",
        ],
        version = "6.4",
        tags = FIXTURE_TAGS,
    )

    native.config_setting(
        name = namer("xcode_5_1_2"),
        flag_values = {namer(":flag_propagator"): "5.1.2"},
    )

    native.config_setting(
        name = namer("xcode_6_4"),
        flag_values = {namer(":flag_propagator"): "6.4"},
    )

    native.genrule(
        name = namer("gen"),
        srcs = [],
        outs = [namer("out")],
        cmd = select({
            namer(":xcode_5_1_2"): "5.1.2",
            namer(":xcode_6_4"): "6.4",
            "//conditions:default": "none",
        }),
        tags = FIXTURE_TAGS,
    )

    _default_version_config_setting_no_flag_test(
        name = "default_version_config_setting_no_flag",
        target_under_test = namer("gen"),
    )
    _default_version_config_setting_6_4_test(
        name = "default_version_config_setting_6_4",
        target_under_test = namer("gen"),
    )
    return [
        "default_version_config_setting_no_flag",
        "default_version_config_setting_6_4",
    ]

def _default_version_config_setting_no_flag_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.true(env, find_action(env, "Genrule").argv[-1].endswith("5.1.2"))
    return analysistest.end(env)

_default_version_config_setting_no_flag_test = analysistest.make(
    _default_version_config_setting_no_flag_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:default_version_config_setting__foo",
        )),
    },
)

def _default_version_config_setting_6_4_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.true(env, find_action(env, "Genrule").argv[-1].endswith("6.4"))
    return analysistest.end(env)

_default_version_config_setting_6_4_test = analysistest.make(
    _default_version_config_setting_6_4_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:default_version_config_setting__foo",
        )),
        "//command_line_option:xcode_version": "6.4",
    },
)

# ------------------------------------------------------------------------------

def _valid_version(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "valid_version__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
        ],
    )

    _valid_version_test(
        name = "valid_version",
        target_under_test = "valid_version__foo",
    )
    return ["valid_version"]

def _valid_version_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_valid_version_test = analysistest.make(
    _valid_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "5.1.2",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:valid_version__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _valid_alias_dotted_version(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "valid_alias_dotted_version__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["5"]),
        ],
    )

    _valid_alias_dotted_version_test(
        name = "valid_alias_dotted_version",
        target_under_test = "valid_alias_dotted_version__foo",
    )
    return ["valid_alias_dotted_version"]

def _valid_alias_dotted_version_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_valid_alias_dotted_version_test = analysistest.make(
    _valid_alias_dotted_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "5",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:valid_alias_dotted_version__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _valid_alias_nonnumerical(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "valid_alias_nonnumerical__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["valid_version"]),
        ],
    )

    _valid_alias_nonnumerical_test(
        name = "valid_alias_nonnumerical",
        target_under_test = "valid_alias_nonnumerical__foo",
    )
    return ["valid_alias_nonnumerical"]

def _valid_alias_nonnumerical_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_valid_alias_nonnumerical_test = analysistest.make(
    _valid_alias_nonnumerical_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "valid_version",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:valid_alias_nonnumerical__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _invalid_xcode_specified(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "invalid_xcode_specified__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
            struct(name = "version84", version = "8.4"),
        ],
    )

    _invalid_xcode_specified_test(
        name = "invalid_xcode_specified",
        target_under_test = "invalid_xcode_specified__foo",
    )
    return ["invalid_xcode_specified"]

def _invalid_xcode_specified_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "--xcode_version=6 specified, but '6' is not an available Xcode version. If you believe you have '6' installed")
    return analysistest.end(env)

_invalid_xcode_specified_test = analysistest.make(
    _invalid_xcode_specified_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "6",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:invalid_xcode_specified__foo",
        )),
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _requires_default(namer):
    xcode_config(
        name = "requires_default__foo",
        versions = [namer(":version512")],
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        version = "5.1.2",
    )

    _requires_default_test(
        name = "requires_default",
        target_under_test = "requires_default__foo",
    )
    return ["requires_default"]

def _requires_default_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "default version must be specified")
    return analysistest.end(env)

_requires_default_test = analysistest.make(
    _requires_default_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "6",
        "//command_line_option:xcode_version_config": str(Label(
            "//test:requires_default__foo",
        )),
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _duplicate_aliases_defined_version(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "duplicate_aliases_defined_version__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["5"]),
            struct(name = "version5", version = "5.0", aliases = ["5"]),
        ],
    )

    _duplicate_aliases_defined_version_test(
        name = "duplicate_aliases_defined_version",
        target_under_test = "duplicate_aliases_defined_version__foo",
    )
    return ["duplicate_aliases_defined_version"]

def _duplicate_aliases_defined_version_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "'5' is registered to multiple labels")
    asserts.expect_failure(env, "__version512")
    asserts.expect_failure(env, "__version5")
    return analysistest.end(env)

_duplicate_aliases_defined_version_test = analysistest.make(
    _duplicate_aliases_defined_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:duplicate_aliases_defined_version__foo",
        )),
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _duplicate_aliases_within_available_xcodes(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "duplicate_aliases_within_available_xcodes__foo",
        remote_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["5"]),
            struct(name = "version5", version = "5.0", aliases = ["5"]),
        ],
        local_versions = [
            struct(name = "version5", version = "5.0", is_default = True, aliases = ["5"]),
        ],
    )

    _duplicate_aliases_within_available_xcodes_test(
        name = "duplicate_aliases_within_available_xcodes",
        target_under_test = "duplicate_aliases_within_available_xcodes__foo",
    )
    return ["duplicate_aliases_within_available_xcodes"]

def _duplicate_aliases_within_available_xcodes_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "'5' is registered to multiple labels")
    asserts.expect_failure(env, "__version512")
    asserts.expect_failure(env, "__version5")
    return analysistest.end(env)

_duplicate_aliases_within_available_xcodes_test = analysistest.make(
    _duplicate_aliases_within_available_xcodes_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:duplicate_aliases_within_available_xcodes__foo",
        )),
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _version_aliased_to_itself(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "version_aliased_to_itself__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["5.1.2"]),
        ],
    )

    _version_aliased_to_itself_test(
        name = "version_aliased_to_itself",
        target_under_test = "version_aliased_to_itself__foo",
    )
    return ["version_aliased_to_itself"]

def _version_aliased_to_itself_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_version_aliased_to_itself_test = analysistest.make(
    _version_aliased_to_itself_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:version_aliased_to_itself__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _duplicate_version_numbers(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "duplicate_version_numbers__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
            struct(name = "version5", version = "5.1.2", aliases = ["5"]),
        ],
    )

    _duplicate_version_numbers_test(
        name = "duplicate_version_numbers",
        target_under_test = "duplicate_version_numbers__foo",
    )
    return ["duplicate_version_numbers"]

def _duplicate_version_numbers_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "'5.1.2' is registered to multiple labels")
    asserts.expect_failure(env, "__version512")
    asserts.expect_failure(env, "__version5")
    return analysistest.end(env)

_duplicate_version_numbers_test = analysistest.make(
    _duplicate_version_numbers_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:duplicate_version_numbers__foo",
        )),
        "//command_line_option:xcode_version": "5",
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _version_conflicts_with_alias(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "version_conflicts_with_alias__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True),
            struct(name = "version5", version = "5.0", aliases = ["5.1.2"]),
        ],
    )

    _version_conflicts_with_alias_test(
        name = "version_conflicts_with_alias",
        target_under_test = "version_conflicts_with_alias__foo",
    )
    return ["version_conflicts_with_alias"]

def _version_conflicts_with_alias_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "'5.1.2' is registered to multiple labels")
    asserts.expect_failure(env, "__version512")
    asserts.expect_failure(env, "__version5")
    return analysistest.end(env)

_version_conflicts_with_alias_test = analysistest.make(
    _version_conflicts_with_alias_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:version_conflicts_with_alias__foo",
        )),
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _default_ios_sdk_version(namer):
    xcode_config(
        name = "default_ios_sdk_version__foo",
        default = namer(":version512"),
        versions = [
            namer(":version512"),
            namer(":version64"),
        ],
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        default_ios_sdk_version = "7.1",
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version64"),
        aliases = [
            "6.0",
            "foo",
            "6",
        ],
        default_ios_sdk_version = "43.0",
        version = "6.4",
        tags = FIXTURE_TAGS,
    )

    _default_ios_sdk_version_test(
        name = "default_ios_sdk_version",
        target_under_test = "default_ios_sdk_version__foo",
    )
    return ["default_ios_sdk_version"]

def _default_ios_sdk_version_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "7.1", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.ios_simulator)))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_default_ios_sdk_version_test = analysistest.make(
    _default_ios_sdk_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:default_ios_sdk_version__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _default_sdk_versions(namer):
    xcode_config(
        name = "default_sdk_versions__foo",
        default = namer(":version512"),
        versions = [
            namer(":version512"),
            namer(":version64"),
        ],
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        default_ios_sdk_version = "101",
        default_macos_sdk_version = "104",
        default_tvos_sdk_version = "103",
        default_visionos_sdk_version = "105",
        default_watchos_sdk_version = "102",
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version64"),
        aliases = [
            "6.0",
            "foo",
            "6",
        ],
        default_ios_sdk_version = "43.0",
        version = "6.4",
        tags = FIXTURE_TAGS,
    )

    _default_sdk_versions_test(
        name = "default_sdk_versions",
        target_under_test = "default_sdk_versions__foo",
    )
    return ["default_sdk_versions"]

def _default_sdk_versions_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "101", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.ios_simulator)))
    asserts.equals(env, "102", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.watchos_simulator)))
    asserts.equals(env, "103", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.tvos_simulator)))
    asserts.equals(env, "104", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.macos)))
    asserts.equals(env, "105", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.visionos_simulator)))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_default_sdk_versions_test = analysistest.make(
    _default_sdk_versions_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:default_sdk_versions__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _default_sdk_versions_selected_xcode(namer):
    xcode_config(
        name = "default_sdk_versions_selected_xcode__foo",
        default = namer(":version512"),
        versions = [
            namer(":version512"),
            namer(":version64"),
        ],
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        default_ios_sdk_version = "7.1",
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version64"),
        aliases = [
            "6.0",
            "foo",
            "6",
        ],
        default_ios_sdk_version = "43",
        default_macos_sdk_version = "46",
        default_tvos_sdk_version = "45",
        default_visionos_sdk_version = "47",
        default_watchos_sdk_version = "44",
        version = "6.4",
        tags = FIXTURE_TAGS,
    )

    _default_sdk_versions_selected_xcode_test(
        name = "default_sdk_versions_selected_xcode",
        target_under_test = "default_sdk_versions_selected_xcode__foo",
    )
    return ["default_sdk_versions_selected_xcode"]

def _default_sdk_versions_selected_xcode_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "6.4", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "43", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.ios_simulator)))
    asserts.equals(env, "44", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.watchos_simulator)))
    asserts.equals(env, "45", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.tvos_simulator)))
    asserts.equals(env, "46", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.macos)))
    asserts.equals(env, "47", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.visionos_simulator)))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_default_sdk_versions_selected_xcode_test = analysistest.make(
    _default_sdk_versions_selected_xcode_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:default_sdk_versions_selected_xcode__foo",
        )),
        "//command_line_option:xcode_version": "6",
    },
)

# ------------------------------------------------------------------------------

def _override_default_sdk_versions(namer):
    xcode_config(
        name = "override_default_sdk_versions__foo",
        default = namer(":version512"),
        versions = [
            namer(":version512"),
            namer(":version64"),
        ],
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
        ],
        default_ios_sdk_version = "7.1",
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version64"),
        aliases = [
            "6.0",
            "foo",
            "6",
        ],
        default_ios_sdk_version = "101",
        default_macos_sdk_version = "104",
        default_tvos_sdk_version = "103",
        default_visionos_sdk_version = "105",
        default_watchos_sdk_version = "102",
        version = "6.4",
        tags = FIXTURE_TAGS,
    )

    _override_default_sdk_versions_test(
        name = "override_default_sdk_versions",
        target_under_test = "override_default_sdk_versions__foo",
    )
    return ["override_default_sdk_versions"]

def _override_default_sdk_versions_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "6.4", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "15.3", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.ios_simulator)))
    asserts.equals(env, "15.4", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.watchos_simulator)))
    asserts.equals(env, "15.5", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.tvos_simulator)))
    asserts.equals(env, "15.6", str(xcode_version_info.sdk_version_for_platform(apple_common.platform.macos)))
    asserts.equals(env, "unknown", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_override_default_sdk_versions_test = analysistest.make(
    _override_default_sdk_versions_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:override_default_sdk_versions__foo",
        )),
        "//command_line_option:xcode_version": "6",
        "//command_line_option:ios_sdk_version": "15.3",
        "//command_line_option:watchos_sdk_version": "15.4",
        "//command_line_option:tvos_sdk_version": "15.5",
        "//command_line_option:macos_sdk_version": "15.6",
    },
)

# ------------------------------------------------------------------------------

def _default_without_version(namer):
    xcode_config(
        name = "default_without_version__foo",
        default = namer(":version512"),
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
            "5.1.2",
        ],
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )

    _default_without_version_test(
        name = "default_without_version",
        target_under_test = "default_without_version__foo",
    )
    return ["default_without_version"]

def _default_without_version_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "default label")
    asserts.expect_failure(env, "must be contained in versions attribute")
    return analysistest.end(env)

_default_without_version_test = analysistest.make(
    _default_without_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:default_without_version__foo",
        )),
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _version_does_not_contain_default(namer):
    xcode_config(
        name = "version_does_not_contain_default__foo",
        default = namer(":version512"),
        versions = [namer(":version6")],
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version512"),
        aliases = [
            "5",
            "5.1",
            "5.1.2",
        ],
        version = "5.1.2",
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version6"),
        version = "6.0",
        tags = FIXTURE_TAGS,
    )

    _version_does_not_contain_default_test(
        name = "version_does_not_contain_default",
        target_under_test = "version_does_not_contain_default__foo",
    )
    return ["version_does_not_contain_default"]

def _version_does_not_contain_default_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "must be contained in versions attribute")
    return analysistest.end(env)

_version_does_not_contain_default_test = analysistest.make(
    _version_does_not_contain_default_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:version_does_not_contain_default__foo",
        )),
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _configuration_field_for_rule(namer):
    # Verifies that the `--xcode_version_config` configuration value can be
    # accessed via the `configuration_field()`.
    xcode_config(
        name = "configuration_field_for_rule__config1",
        default = namer(":version1"),
        versions = [namer(":version1")],
        tags = FIXTURE_TAGS,
    )
    xcode_config(
        name = "configuration_field_for_rule__config2",
        default = namer(":version2"),
        versions = [namer(":version2")],
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version1"),
        version = "1.0",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version2"),
        version = "2.0",
        tags = FIXTURE_TAGS,
    )

    provider_grabber(
        name = namer("provider_grabber"),
        tags = FIXTURE_TAGS,
    )

    _configuration_field_for_rule_1_test(
        name = "configuration_field_for_rule_1",
        target_under_test = namer("provider_grabber"),
    )
    _configuration_field_for_rule_2_test(
        name = "configuration_field_for_rule_2",
        target_under_test = namer("provider_grabber"),
    )
    return [
        "configuration_field_for_rule_1",
        "configuration_field_for_rule_2",
    ]

def _configuration_field_for_rule_1_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "1.0", str(xcode_version_info.xcode_version()))

    return analysistest.end(env)

_configuration_field_for_rule_1_test = analysistest.make(
    _configuration_field_for_rule_1_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:configuration_field_for_rule__config1",
        )),
    },
)

def _configuration_field_for_rule_2_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "2.0", str(xcode_version_info.xcode_version()))

    return analysistest.end(env)

_configuration_field_for_rule_2_test = analysistest.make(
    _configuration_field_for_rule_2_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:configuration_field_for_rule__config2",
        )),
    },
)

# ------------------------------------------------------------------------------

def _configuration_field_for_aspect(namer):
    # Verifies that the `--xcode_version_config` configuration value can be
    # accessed via the `configuration_field()`.
    xcode_config(
        name = "configuration_field_for_aspect__config1",
        default = namer(":version1"),
        versions = [namer(":version1")],
        tags = FIXTURE_TAGS,
    )
    xcode_config(
        name = "configuration_field_for_aspect__config2",
        default = namer(":version2"),
        versions = [namer(":version2")],
        tags = FIXTURE_TAGS,
    )

    xcode_version(
        name = namer("version1"),
        version = "1.0",
        tags = FIXTURE_TAGS,
    )
    xcode_version(
        name = namer("version2"),
        version = "2.0",
        tags = FIXTURE_TAGS,
    )

    native.filegroup(
        name = namer("dummy"),
        tags = FIXTURE_TAGS,
    )
    provider_grabber_with_aspect(
        name = namer("provider_grabber"),
        deps = [namer("dummy")],
        tags = FIXTURE_TAGS,
    )

    _configuration_field_for_aspect_1_test(
        name = "configuration_field_for_aspect_1",
        target_under_test = namer("provider_grabber"),
    )
    _configuration_field_for_aspect_2_test(
        name = "configuration_field_for_aspect_2",
        target_under_test = namer("provider_grabber"),
    )
    return [
        "configuration_field_for_aspect_1",
        "configuration_field_for_aspect_2",
    ]

def _configuration_field_for_aspect_1_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "1.0", str(xcode_version_info.xcode_version()))

    return analysistest.end(env)

_configuration_field_for_aspect_1_test = analysistest.make(
    _configuration_field_for_aspect_1_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:configuration_field_for_aspect__config1",
        )),
    },
)

def _configuration_field_for_aspect_2_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "2.0", str(xcode_version_info.xcode_version()))

    return analysistest.end(env)

_configuration_field_for_aspect_2_test = analysistest.make(
    _configuration_field_for_aspect_2_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:configuration_field_for_aspect__config2",
        )),
    },
)

# ------------------------------------------------------------------------------

def _explicit_xcodes_mode_no_flag(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "explicit_xcodes_mode_no_flag__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["5", "5.1"]),
            struct(name = "version64", version = "6.4", aliases = ["6.0", "foo", "6"]),
        ],
    )

    _explicit_xcodes_mode_no_flag_test(
        name = "explicit_xcodes_mode_no_flag",
        target_under_test = "explicit_xcodes_mode_no_flag__foo",
    )
    return ["explicit_xcodes_mode_no_flag"]

def _explicit_xcodes_mode_no_flag_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))

    return analysistest.end(env)

_explicit_xcodes_mode_no_flag_test = analysistest.make(
    _explicit_xcodes_mode_no_flag_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:explicit_xcodes_mode_no_flag__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _explicit_xcodes_mode_with_flag(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "explicit_xcodes_mode_with_flag__foo",
        explicit_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["5", "5.1"]),
            struct(name = "version64", version = "6.4", aliases = ["6.0", "foo", "6"]),
        ],
    )

    _explicit_xcodes_mode_with_flag_test(
        name = "explicit_xcodes_mode_with_flag",
        target_under_test = "explicit_xcodes_mode_with_flag__foo",
    )
    return ["explicit_xcodes_mode_with_flag"]

def _explicit_xcodes_mode_with_flag_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "6.4", str(xcode_version_info.xcode_version()))

    return analysistest.end(env)

_explicit_xcodes_mode_with_flag_test = analysistest.make(
    _explicit_xcodes_mode_with_flag_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:explicit_xcodes_mode_with_flag__foo",
        )),
        "//command_line_option:xcode_version": "6.4",
    },
)

# ------------------------------------------------------------------------------

def _available_xcodes_mode_no_flag(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "available_xcodes_mode_no_flag__foo",
        remote_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["5", "5.1"]),
            struct(name = "version84", version = "8.4"),
        ],
        local_versions = [
            struct(name = "version84", version = "8.4", is_default = True),
        ],
    )

    _available_xcodes_mode_no_flag_test(
        name = "available_xcodes_mode_no_flag",
        target_under_test = "available_xcodes_mode_no_flag__foo",
    )
    return ["available_xcodes_mode_no_flag"]

def _available_xcodes_mode_no_flag_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "8.4", str(xcode_version_info.xcode_version()))

    return analysistest.end(env)

_available_xcodes_mode_no_flag_test = analysistest.make(
    _available_xcodes_mode_no_flag_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:available_xcodes_mode_no_flag__foo",
        )),
    },
)

# ------------------------------------------------------------------------------

def _available_xcodes_mode_different_alias(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "available_xcodes_mode_different_alias__foo",
        remote_versions = [
            struct(name = "version5", version = "5.1", is_default = True, aliases = ["5"]),
        ],
        local_versions = [
            struct(name = "version5.1.2", version = "5.1.2", is_default = True, aliases = ["5"]),
        ],
    )

    _available_xcodes_mode_different_alias_test(
        name = "available_xcodes_mode_different_alias",
        target_under_test = "available_xcodes_mode_different_alias__foo",
    )
    return ["available_xcodes_mode_different_alias"]

def _available_xcodes_mode_different_alias_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "Xcode version 5 was selected")
    asserts.expect_failure(env, "This corresponds to local Xcode version 5.1.2")
    return analysistest.end(env)

_available_xcodes_mode_different_alias_test = analysistest.make(
    _available_xcodes_mode_different_alias_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:available_xcodes_mode_different_alias__foo",
        )),
        "//command_line_option:xcode_version": "5",
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _available_xcodes_mode_different_alias_fully_specified(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "available_xcodes_mode_different_alias_fully_specified__foo",
        remote_versions = [
            struct(name = "version5", version = "5.1", is_default = True, aliases = ["5"]),
        ],
        local_versions = [
            struct(name = "version5.1.2", version = "5.1.2", is_default = True, aliases = ["5"]),
        ],
    )

    _available_xcodes_mode_different_alias_fully_specified_test(
        name = "available_xcodes_mode_different_alias_fully_specified",
        target_under_test = "available_xcodes_mode_different_alias_fully_specified__foo",
    )
    return ["available_xcodes_mode_different_alias_fully_specified"]

def _available_xcodes_mode_different_alias_fully_specified_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())

    return analysistest.end(env)

_available_xcodes_mode_different_alias_fully_specified_test = analysistest.make(
    _available_xcodes_mode_different_alias_fully_specified_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:available_xcodes_mode_different_alias_fully_specified__foo",
        )),
        "//command_line_option:xcode_version": "5.1.2",
    },
)

# ------------------------------------------------------------------------------

def _available_xcodes_mode_with_flag(namer):
    _make_xcode_fixtures(
        namer = namer,
        xcode_config_name = "available_xcodes_mode_with_flag__foo",
        remote_versions = [
            struct(name = "version512", version = "5.1.2", is_default = True, aliases = ["5", "5.1"]),
            struct(name = "version84", version = "8.4"),
        ],
        local_versions = [
            struct(name = "version84", version = "8.4", is_default = True),
        ],
    )

    _available_xcodes_mode_with_flag_test(
        name = "available_xcodes_mode_with_flag",
        target_under_test = "available_xcodes_mode_with_flag__foo",
    )
    return ["available_xcodes_mode_with_flag"]

def _available_xcodes_mode_with_flag_test_impl(ctx):
    env = analysistest.begin(ctx)

    target_under_test = analysistest.target_under_test(env)
    xcode_version_info = target_under_test[apple_common.XcodeVersionConfig]

    asserts.equals(env, "5.1.2", str(xcode_version_info.xcode_version()))

    return analysistest.end(env)

_available_xcodes_mode_with_flag_test = analysistest.make(
    _available_xcodes_mode_with_flag_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": str(Label(
            "//test:available_xcodes_mode_with_flag__foo",
        )),
        "//command_line_option:xcode_version": "5.1.2",
    },
)

# ------------------------------------------------------------------------------

def _make_xcode_fixtures(
        *,
        namer,
        xcode_config_name,
        remote_versions = [],
        local_versions = [],
        explicit_versions = []):
    """Helper function to splat out fixtures used by multiple tests."""
    all_versions = {}

    remote_default_label = None
    for version_info in remote_versions:
        version_name = version_info.name
        all_versions[version_name] = version_info
        if getattr(version_info, "is_default", False):
            if remote_default_label:
                fail("Only one remote version may be the default")
            remote_default_label = version_name

    local_default_label = None
    for version_info in local_versions:
        version_name = version_info.name
        all_versions[version_name] = version_info
        if getattr(version_info, "is_default", False):
            if local_default_label:
                fail("Only one local version may be the default")
            local_default_label = version_name

    explicit_default_label = None
    for version_info in explicit_versions:
        version_name = version_info.name
        all_versions[version_name] = version_info
        if getattr(version_info, "is_default", False):
            if explicit_default_label:
                fail("Only one explicit version may be the default")
            explicit_default_label = version_name

    for version_name, version in all_versions.items():
        xcode_version(
            name = namer(version.name),
            version = version.version,
            aliases = getattr(version, "aliases", []),
            tags = FIXTURE_TAGS,
        )

    if local_versions or remote_versions:
        if local_versions:
            available_xcodes(
                name = namer("local"),
                default = namer(local_default_label),
                versions = [namer(version.name) for version in local_versions],
                tags = FIXTURE_TAGS,
            )
        if remote_versions:
            available_xcodes(
                name = namer("remote"),
                default = namer(remote_default_label),
                versions = [namer(version.name) for version in remote_versions],
                tags = FIXTURE_TAGS,
            )
        xcode_config(
            name = xcode_config_name,
            local_versions = namer("local"),
            remote_versions = namer("remote"),
            tags = FIXTURE_TAGS,
        )

    if explicit_versions:
        xcode_config(
            name = xcode_config_name,
            default = namer(explicit_default_label),
            versions = [namer(version.name) for version in explicit_versions],
            tags = FIXTURE_TAGS,
        )

# ------------------------------------------------------------------------------

def xcode_config_test(name):
    make_all_tests(
        name = name,
        tests = [
            _mutual_and_explicit_xcodes_fails,
            _mutual_and_default_xcodes_fails,
            _no_local_xcodes_fails,
            _accepts_flag_for_mutually_available,
            _prefers_flag_over_mutually_available,
            _warn_with_explicit_local_only_version,
            _prefer_local_default_if_no_mutual_no_flag_different_main_version,
            _prefer_local_default_if_no_mutual_no_flag_different_build_alias,
            _prefer_local_default_if_no_mutual_no_flag_different_full_version,
            _choose_newest_mutual_xcode,
            _invalid_xcode_from_mutual_throws,
            _apple_common_xcode_version_config_constructor,
            _apple_common_xcode_version_config_constructor_fails_on_bad_input,
            _config_alias_config_setting,
            _default_version_config_setting,
            _valid_version,
            _valid_alias_dotted_version,
            _valid_alias_nonnumerical,
            _invalid_xcode_specified,
            _requires_default,
            _duplicate_aliases_defined_version,
            _duplicate_aliases_within_available_xcodes,
            _version_aliased_to_itself,
            _duplicate_version_numbers,
            _version_conflicts_with_alias,
            _default_ios_sdk_version,
            _default_sdk_versions,
            _default_sdk_versions_selected_xcode,
            _override_default_sdk_versions,
            _default_without_version,
            _version_does_not_contain_default,
            _configuration_field_for_rule,
            _configuration_field_for_aspect,
            _explicit_xcodes_mode_no_flag,
            _explicit_xcodes_mode_with_flag,
            _available_xcodes_mode_no_flag,
            _available_xcodes_mode_different_alias,
            _available_xcodes_mode_different_alias_fully_specified,
            _available_xcodes_mode_with_flag,
        ] if bazel_features.apple.xcode_config_migrated else [],
    )

    # TODO: b/311385128 - The following tests from `XcodeConfigTest.java`
    # couldn't be migrated to Starlark, because they need to set an
    # `--experimental_*` flag, which is not supported in Starlark transitions:
    #
    # *   testPreferMutual_choosesLocalDefaultOverNewest
    # *   testPreferMutualXcodeFalseOverridesMutual
    # *   testLocalDefaultCanBeMutuallyAvailable
    # *   testPreferLocalDefaultOverDifferentBuild
    # *   testXcodeWithExtensionMatchingRemote
    # *   testXcodeVersionWithExtensionMatchingRemoteAndLocal
    # *   testXcodeVersionWithNoExtension
