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

"""Implementation of the `xcode_config_resolver` build rule."""

load(
    "@build_bazel_apple_support//build_settings:build_settings.bzl",
    "read_possibly_native_flag",
)
load(
    "@build_bazel_apple_support//xcode/private:providers.bzl",
    "XcodeVersionPropertiesInfo",
)

visibility("public")

def _xcode_config_resolver_impl(ctx):
    """Gates between the native default and the Starlark flag."""

    # Resolution logic is centralized in read_possibly_native_flag.
    resolved_target = read_possibly_native_flag(ctx, "xcode_version_config")

    if not resolved_target:
        fail("Failed to resolve Xcode configuration.")

    return [
        resolved_target[apple_common.XcodeVersionConfig],
        resolved_target[XcodeVersionPropertiesInfo],
    ]

# This is a temporary implementation while the migration from native Xcode
# configuration to Starlark flags is ongoing. Once the native fragment is
# removed, this rule will be unnecessary and will be removed.
#
# This target should be used by rule implementations (via an attribute default)
# to read the resolved Xcode configuration.
#
# IMPORTANT: The resolved value should always be controlled using the
# --xcode_version_config flag. The selection between the native configuration
# field and the Starlark flag is handled automatically by the implementation of
# this rule. When the native fragment is removed, it is assumed that an alias
# will be in place to propagate the --xcode_version_config value to the Starlark
# @build_bazel_apple_support//xcode:starlark_version_config flag.
xcode_config_resolver = rule(
    implementation = _xcode_config_resolver_impl,
    attrs = {
        "_xcode_version_config": attr.label(
            default = "@build_bazel_apple_support//xcode:starlark_version_config",
        ),
        "_xcode_version_config_native": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
    },
    fragments = ["apple"],
)
