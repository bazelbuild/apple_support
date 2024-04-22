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

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(
    "@build_bazel_apple_support//xcode:available_xcodes.bzl",
    "available_xcodes",
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
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:accepts_flag_for_mutually_available__foo",
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

    return analysistest.end(env)

_prefers_flag_over_mutually_available_test = analysistest.make(
    _prefers_flag_over_mutually_available_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "5.1.2",
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:prefers_flag_over_mutually_available__foo",
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

    # TODO: b/311385128 - Once we move the rules to apple_support, hack up
    # something that would let us actually test the warning messages. We can't
    # test `print`.

    asserts.equals(env, "8.4", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-remote" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_warn_with_explicit_local_only_version_test = analysistest.make(
    _warn_with_explicit_local_only_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version": "8.4",
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:warn_with_explicit_local_only_version__foo",
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

    # TODO: b/311385128 - Once we move the rules to apple_support, hack up
    # something that would let us actually test the warning messages. We can't
    # test `print`.

    asserts.equals(env, "8.4", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-remote" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_prefer_local_default_if_no_mutual_no_flag_different_main_version_test = analysistest.make(
    _prefer_local_default_if_no_mutual_no_flag_different_main_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:prefer_local_default_if_no_mutual_no_flag_different_main_version__foo",
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

    # TODO: b/311385128 - Once we move the rules to apple_support, hack up
    # something that would let us actually test the warning messages. We can't
    # test `print`.

    asserts.equals(env, "10.0.0.10C504", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-remote" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_prefer_local_default_if_no_mutual_no_flag_different_build_alias_test = analysistest.make(
    _prefer_local_default_if_no_mutual_no_flag_different_build_alias_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:prefer_local_default_if_no_mutual_no_flag_different_build_alias__foo",
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

    # TODO: b/311385128 - Once we move the rules to apple_support, hack up
    # something that would let us actually test the warning messages. We can't
    # test `print`.

    asserts.equals(env, "10.0.0.10C504", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "local", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "no-remote" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_prefer_local_default_if_no_mutual_no_flag_different_full_version_test = analysistest.make(
    _prefer_local_default_if_no_mutual_no_flag_different_full_version_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:prefer_local_default_if_no_mutual_no_flag_different_full_version__foo",
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

    # TODO: b/311385128 - Once we move the rules to apple_support, hack up
    # something that would let us actually test the warning messages. We can't
    # test `print`.

    asserts.equals(env, "10", str(xcode_version_info.xcode_version()))
    asserts.equals(env, "both", xcode_version_info.availability())
    asserts.true(env, "requires-darwin" in xcode_version_info.execution_info())
    asserts.true(env, "supports-xcode-requirements-set" in xcode_version_info.execution_info())

    return analysistest.end(env)

_choose_newest_mutual_xcode_test = analysistest.make(
    _choose_newest_mutual_xcode_test_impl,
    config_settings = {
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:choose_newest_mutual_xcode__foo",
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
        "//command_line_option:xcode_version_config": "@build_bazel_apple_support//test:invalid_xcode_from_mutual_throws__foo",
    },
    expect_failure = True,
)

# ------------------------------------------------------------------------------

def _make_xcode_fixtures(
        *,
        namer,
        xcode_config_name,
        remote_versions = [],
        local_versions = []):
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
        )

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
        ],
    )

    # TODO: b/311385128 - The following tests from `XcodeConfigTest.java`
    # couldn't be migrated to Starlark, because they need to set an
    # `--experimental_*` flag, which is not supported in Starlark transitions:
    #
    # *   testPreferMutual_choosesLocalDefaultOverNewest
    # *   testPreferMutualXcodeFalseOverridesMutual
    # *   testLocalDefaultCanBeMutuallyAvailable
    # *   testPreferLocalDefaultOverDifferentBuild
