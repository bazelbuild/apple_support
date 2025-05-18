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

"""Implementation of the `xcode_version` build rule."""

load("@bazel_features//:features.bzl", "bazel_features")
load(
    "@build_bazel_apple_support//xcode:providers.bzl",
    "XcodeSdkVariantInfo",
)
load(
    "@build_bazel_apple_support//xcode/private:providers.bzl",
    "XcodeVersionPropertiesInfo",
    "XcodeVersionRuleInfo",
)

visibility("public")

def _xcode_version_impl(ctx):
    # TODO: remove when we test with Bazel 8+
    if not bazel_features.apple.xcode_config_migrated:
        fail("This rule is not available on the current Bazel version")

    if ctx.attr.sdk:
        sdk_variant_info = ctx.attr.sdk[XcodeSdkVariantInfo]
    else:
        # We intentionally don't fail here if no SDK is present. Instead, we do
        # this inside `xcode_config` once we've resolved the specific Xcode that
        # we're using in the build.
        sdk_variant_info = None

    xcode_version_properties = XcodeVersionPropertiesInfo(
        xcode_version = ctx.attr.version,
        default_ios_sdk_version = ctx.attr.default_ios_sdk_version,
        default_visionos_sdk_version = ctx.attr.default_visionos_sdk_version,
        default_watchos_sdk_version = ctx.attr.default_watchos_sdk_version,
        default_tvos_sdk_version = ctx.attr.default_tvos_sdk_version,
        default_macos_sdk_version = ctx.attr.default_macos_sdk_version,
        sdk_variant_info = sdk_variant_info,
    )
    return [
        xcode_version_properties,
        XcodeVersionRuleInfo(
            label = ctx.label,
            xcode_version_properties = xcode_version_properties,
            aliases = ctx.attr.aliases,
        ),
        DefaultInfo(runfiles = ctx.runfiles()),
    ]

xcode_version = rule(
    attrs = {
        "aliases": attr.string_list(
            doc = """\
Accepted aliases for this version of Xcode. If the value of the
`--xcode_version` build flag matches any of the given alias strings, this Xcode
version will be used.
""",
            allow_empty = True,
            mandatory = False,
        ),
        "default_ios_sdk_version": attr.string(
            default = "8.4",
            doc = """\
The iOS SDK version that is used by default when this version of Xcode is being
used. The `--ios_sdk_version` build flag will override the value specified here.

NOTE: The `--ios_sdk_version` flag is deprecated and not recommended for use.
""",
            mandatory = False,
        ),
        "default_macos_sdk_version": attr.string(
            default = "10.11",
            doc = """\
The macOS SDK version that is used by default when this version of Xcode is
being used. The `--macos_sdk_version` build flag will override the value
specified here.

NOTE: The `--macos_sdk_version` flag is deprecated and not recommended for use.
""",
            mandatory = False,
        ),
        "default_tvos_sdk_version": attr.string(
            default = "9.0",
            doc = """\
The tvOS SDK version that is used by default when this version of Xcode is being
used. The `--tvos_sdk_version` build flag will override the value specified
here.

NOTE: The `--tvos_sdk_version` flag is deprecated and not recommended for use.
""",
            mandatory = False,
        ),
        "default_visionos_sdk_version": attr.string(
            default = "1.0",
            doc = """\
The visionOS SDK version that is used by default when this version of Xcode is
being used.
""",
            mandatory = False,
        ),
        "default_watchos_sdk_version": attr.string(
            default = "2.0",
            doc = """\
The watchOS SDK version that is used by default when this version of Xcode is
being used. The `--watchos_sdk_version` build flag will override the value
specified here.

NOTE: The `--watchos_sdk_version` flag is deprecated and not recommended for
use.
""",
            mandatory = False,
        ),
        "sdk": attr.label(
            doc = """\
The `xcode_sdk_variant` target that represents the SDK in this version of Xcode
to build with under the current target configuration. This attribute will
typically be assigned via a `select({...})` expression that selects the
appropriate `xcode_sdk_variant` target based on the target configuration's
operating system and environment constraints.
""",
            mandatory = False,
            providers = [[XcodeSdkVariantInfo]],
        ),
        "version": attr.string(
            doc = "The official version number for this version of Xcode.",
            mandatory = True,
        ),
    },
    implementation = _xcode_version_impl,
)
