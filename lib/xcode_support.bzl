# Copyright 2019 The Bazel Authors. All rights reserved.
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

"""Support functions for working with Xcode configurations."""

load(
    "@build_bazel_apple_support//xcode:providers.bzl",
    "XcodeSdkVariantInfo",
)

visibility("public")

def _get_current_sdk(ctx):
    """Returns the `XcodeSdkVariantInfo` provider for the current configuration.

    Callers of this function must define the `_xcode_config` attribute in their
    rule or aspect. This is best done using the
    `apple_support.action_required_attrs()` helper.

    Args:
        ctx: The rule or aspect context.

    Returns:
        The `XcodeSdkVariantInfo` provider for the current configuration.
    """
    xcode_config = getattr(ctx.attr, "_xcode_config")
    if not xcode_config or XcodeSdkVariantInfo not in xcode_config:
        fail("Failed to read the Xcode configuration from the current " +
             "context. Does the calling rule or aspect correctly define the " +
             "`_xcode_config` attribute?")
    return xcode_config[XcodeSdkVariantInfo]

def _get_current_xcode(ctx):
    """Returns the `XcodeVersionConfig` provider for the current configuration.

    Callers of this function must define the `_xcode_config` attribute in their
    rule or aspect. This is best done using the
    `apple_support.action_required_attrs()` helper.

    Args:
        ctx: The rule or aspect context.

    Returns:
        The `XcodeVersionConfig` provider for the current configuration.
    """
    xcode_config = getattr(ctx.attr, "_xcode_config")
    if not xcode_config or apple_common.XcodeVersionConfig not in xcode_config:
        fail("Failed to read the Xcode configuration from the current " +
             "context. Does the calling rule or aspect correctly define the " +
             "`_xcode_config` attribute?")
    return xcode_config[apple_common.XcodeVersionConfig]

def _is_xcode_at_least_version(xcode_config, version):
    """Returns True if Xcode version is at least a given version.

    This method takes as input an `XcodeVersionConfig` provider, which can be obtained from the
    `_xcode_config` attribute (e.g. `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`). This
    provider should contain the Xcode version parameters with which this rule is being built with.
    If you need to add this attribute to your rule implementation, please refer to
    `apple_support.action_required_attrs()`.

    Args:
        xcode_config: The XcodeVersionConfig provider from the `_xcode_config` attribute's value.
        version: The minimum desired Xcode version, as a dotted version string.

    Returns:
        True if the given `xcode_config` version at least as high as the requested version.
    """
    current_version = xcode_config.xcode_version()

    if str(current_version).startswith("/"):
        return True

    if not current_version:
        fail("Could not determine Xcode version at all. This likely means Xcode isn't available; " +
             "if you think this is a mistake, please file an issue.")

    desired_version = apple_common.dotted_version(version)
    return current_version >= desired_version

# Define the loadable module that lists the exported symbols in this file.
xcode_support = struct(
    get_current_sdk = _get_current_sdk,
    get_current_xcode = _get_current_xcode,
    is_xcode_at_least_version = _is_xcode_at_least_version,
)
