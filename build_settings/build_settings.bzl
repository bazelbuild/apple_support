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

"""List of Bazel's apple_support build settings."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

visibility("public")

_POSSIBLY_NATIVE_FLAGS = {
    "xcode_version": (lambda ctx: ctx.fragments.apple.xcode_version_flag, "native"),
    "experimental_prefer_mutual_xcode": (lambda ctx: ctx.fragments.apple.prefer_mutual_xcode, "native"),
    "include_xcode_exec_requirements": (lambda ctx: ctx.fragments.apple.include_xcode_exec_requirements, "native"),
    "ios_minimum_os": (lambda ctx: ctx.fragments.apple.ios_minimum_os_flag, "native"),
    "macos_minimum_os": (lambda ctx: ctx.fragments.apple.macos_minimum_os_flag, "native"),
    "tvos_minimum_os": (lambda ctx: ctx.fragments.apple.tvos_minimum_os_flag, "native"),
    "watchos_minimum_os": (lambda ctx: ctx.fragments.apple.watchos_minimum_os_flag, "native"),
    # xcode_version_config is a configuration field in the apple fragment, so there is no
    # "native" Bazel function to read it. It is assumed that the configuration field is surfaced
    # in the rule's attrs as "_xcode_config".
    "xcode_version_config": (lambda ctx: ctx.attr._xcode_config, "native"),
}

_DOTTED_VERSION_FLAGS = set([
    "ios_minimum_os",
    "macos_minimum_os",
    "tvos_minimum_os",
    "watchos_minimum_os",
])

_LABEL_FLAGS = set([
    "xcode_version_config",
])

def _should_use_native_def(ctx, flag_name, mode):
    """Returns True if the native definition should be used."""

    # If the override to force the Starlark definition for testing/flipping flags one at
    # a time is active, return early.
    if mode == "starlark":
        return False

    # If the apple fragment is active, we should read the native flag.
    if "apple" in dir(ctx.fragments):
        return True

    # Special case: xcode_version_config can be read as a configuration_field attribute
    # even without the apple fragment, provided the attribute is present and resolved.
    if flag_name == "xcode_version_config" and getattr(ctx.attr, "_xcode_config", None):
        return True

    # Fall through case where the fragment is disabled.
    return False

def read_possibly_native_flag(ctx, flag_name):
    """
    Canonical API for reading an Apple build flag.

    Flags might be defined in Starlark or native-Bazel. This function reads flags
    from the correct source based on supporting Bazel version and --incompatible*
    flags that disable native references.

    Args:
        ctx: Rule's configuration context.
        flag_name: Name of the flag to read, without preceding "--".

    Returns:
        The flag's value.
    """
    native_lambda, mode = _POSSIBLY_NATIVE_FLAGS[flag_name]

    if _should_use_native_def(ctx, flag_name, mode):
        return native_lambda(ctx)

    # Starlark definition of "--foo" is assumed to be a label dependency named "_foo".
    if flag_name in _LABEL_FLAGS:
        # Label flags do not use BuildSettingInfo.
        return getattr(ctx.attr, "_" + flag_name)
    build_setting_value = getattr(ctx.attr, "_" + flag_name)[BuildSettingInfo].value

    # Dotted version flags should be converted before accessed.
    if flag_name not in _DOTTED_VERSION_FLAGS:
        return build_setting_value

    # Special check for empty string. This is to simulate the behavior of the native flag
    # default value "null", which avoids triggering parsing logic.
    if build_setting_value:
        return apple_common.dotted_version(build_setting_value)
    return None
