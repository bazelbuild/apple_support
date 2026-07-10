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

"""A rule that allows `select()` to differentiate between Xcode versions."""

load(
    "@build_bazel_apple_support//xcode:providers.bzl",
    "XcodeVersionInfo",
)

visibility("public")

def _strip_or_pad_version(version, num_components):
    """Strips or pads a version string to the given number of components.

    If the version string contains fewer than the requested number of
    components, it will be padded with zeros.

    Args:
        version: The version string.
        num_components: The desired number of components.

    Returns:
        The version, stripped or padded to the requested number of components.
    """
    version_string = str(version)
    components = version_string.split(".")
    if num_components <= len(components):
        return ".".join(components[:num_components])
    return version_string + (".0" * (num_components - len(components)))

_VERSION_PRECISION_COMPONENTS = {
    "major": 1,
    "minor": 2,
    "patch": 3,
}

def _selected_xcode_version_retriever_impl(ctx):
    """A rule that allows select() to differentiate between Xcode versions."""
    xcode_config = ctx.attr._xcode_config[XcodeVersionInfo]
    xcode_version = xcode_config.xcode_version()
    precision = ctx.attr.precision

    if precision == "exact":
        value = str(xcode_version)

    else:
        num_components = _VERSION_PRECISION_COMPONENTS[precision]
        value = _strip_or_pad_version(xcode_version, num_components)

    return config_common.FeatureFlagInfo(value = value)

selected_xcode_version_retriever = rule(
    implementation = _selected_xcode_version_retriever_impl,
    attrs = {
        "precision": attr.string(
            doc = """\
The desired precision with which the version number will be provided. The
permitted values of this attribute are given below, with examples of the value
that the rule would provide if the selected `xcode_version` target reported
`version = "1.2.3.4X789"`:

-   `major`: Provide only the major component of the version number (e.g., `1`).
-   `minor`: Provide only the major and minor components of the version number
    (e.g., `1.2`).
-   `patch`: Provide only the major, minor, and patch components of the version
    number (e.g., `1.2.3`).
-   `exact`: Provide the version number reported by the `xcode_version` target
    unmodified (e.g., `1.2.3.4X789`).
""",
            mandatory = True,
            values = ["major", "minor", "patch", "exact"],
        ),
        "_xcode_config": attr.label(
            default = "@build_bazel_apple_support//xcode:version_config",
        ),
    },
)
