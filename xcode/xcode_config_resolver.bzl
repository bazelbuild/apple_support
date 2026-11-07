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

load("@bazel_features//private:util.bzl", "ge")
load(
    "//xcode:providers.bzl",
    "XcodeVersionPropertiesInfo",
)

visibility("private")

def _native_xcode_config_resolver_impl(ctx):
    return _xcode_config_providers(ctx.attr._xcode_version_config_native)

def _starlark_xcode_config_resolver_impl(ctx):
    return _xcode_config_providers(ctx.attr._xcode_version_config)

def _xcode_config_providers(resolved_target):
    if not resolved_target:
        fail("Failed to resolve Xcode configuration.")

    xcode_version_config = resolved_target[apple_common.XcodeVersionConfig]
    if XcodeVersionPropertiesInfo in resolved_target:
        xcode_version_properties = resolved_target[XcodeVersionPropertiesInfo]
    else:
        xcode_version_properties = _properties_from_legacy_xcode_config(
            xcode_version_config,
        )

    return [
        xcode_version_config,
        xcode_version_properties,
    ]

def _string_or_none(value):
    return str(value) if value else None

def _sdk_version_for_platform(xcode_version_config, platform_name):
    platform = getattr(apple_common.platform, platform_name, None)
    if platform == None:
        return None
    return _string_or_none(xcode_version_config.sdk_version_for_platform(platform))

def _properties_from_legacy_xcode_config(xcode_version_config):
    return XcodeVersionPropertiesInfo(
        xcode_version = _string_or_none(xcode_version_config.xcode_version()),
        default_ios_sdk_version = _sdk_version_for_platform(
            xcode_version_config,
            "ios_device",
        ),
        default_macos_sdk_version = _sdk_version_for_platform(
            xcode_version_config,
            "macos",
        ),
        default_tvos_sdk_version = _sdk_version_for_platform(
            xcode_version_config,
            "tvos_device",
        ),
        default_visionos_sdk_version = _sdk_version_for_platform(
            xcode_version_config,
            "visionos_device",
        ),
        default_watchos_sdk_version = _sdk_version_for_platform(
            xcode_version_config,
            "watchos_device",
        ),
    )

# This is a temporary implementation while the migration from native Xcode
# configuration to Starlark flags is ongoing. Once the native fragment is
# removed, this rule will be unnecessary and will be removed.
#
# This target should be used by rule implementations (via an attribute default)
# to read the resolved Xcode configuration.
#
# IMPORTANT: The resolved value should always be controlled using the
# --xcode_version_config flag. The macro selects the native configuration field
# or the Starlark flag before analysis so the unused configuration is not
# evaluated. When the native fragment is removed, it is assumed that an alias
# will be in place to propagate the --xcode_version_config value to the Starlark
# @apple_support//xcode:starlark_version_config flag.
_native_xcode_config_resolver = rule(
    implementation = _native_xcode_config_resolver_impl,
    attrs = {
        "_xcode_version_config_native": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
    },
    fragments = ["apple"],
)

_starlark_xcode_config_resolver = rule(
    implementation = _starlark_xcode_config_resolver_impl,
    attrs = {
        "_xcode_version_config": attr.label(
            default = "@apple_support//xcode:starlark_version_config",
        ),
    },
)

def xcode_config_resolver(name):
    """Selects the native or Starlark dependency before analyzing the resolver.

    Args:
      name: The name of the target.
    """
    if not ge("10.0.0-pre.20260112.1"):
        _native_xcode_config_resolver(name = name)
        return

    native.config_setting(
        name = name + "_use_starlark",
        values = {"incompatible_remove_ctx_apple_fragment": "true"},
        visibility = ["//visibility:private"],
    )
    _native_xcode_config_resolver(
        name = name + "_native",
        tags = ["manual"],
        visibility = ["//visibility:private"],
    )
    _starlark_xcode_config_resolver(
        name = name + "_starlark",
        tags = ["manual"],
        visibility = ["//visibility:private"],
    )
    native.alias(
        name = name,
        actual = select({
            ":" + name + "_use_starlark": ":" + name + "_starlark",
            "//conditions:default": ":" + name + "_native",
        }),
    )
