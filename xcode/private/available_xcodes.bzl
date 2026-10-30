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

"""Implementation of the `available_xcodes` build rule."""

load(
    "@build_bazel_apple_support//xcode/private:providers.bzl",
    "AvailableXcodesInfo",
    "XcodeVersionRuleInfo",
)

visibility([
    "@build_bazel_apple_support//test/...",
    "@build_bazel_apple_support//xcode/...",
])

def _merge_aliases(info, extra_aliases_by_label):
    """Returns a new `XcodeVersionRuleInfo` provider with extra aliases merged.

    Merges the target's existing aliases with any additional aliases assigned
    to that version label in `extra_aliases_by_label`. Returns the original
    `info` unchanged if no additional aliases are registered for the label.

    Args:
        info: The `XcodeVersionRuleInfo` provider of the target.
        extra_aliases_by_label: A dictionary mapping `Label`s to lists of
            additional alias strings.

    Returns:
        A new `XcodeVersionRuleInfo` provider with the merged aliases, or the
        original `info` if no extra aliases were specified.
    """
    extra_aliases = extra_aliases_by_label.get(info.label)
    if not extra_aliases:
        return info
    merged_aliases = list(info.aliases)
    for alias in extra_aliases:
        if alias not in merged_aliases:
            merged_aliases.append(alias)
    return XcodeVersionRuleInfo(
        label = info.label,
        xcode_version_properties = info.xcode_version_properties,
        aliases = merged_aliases,
    )

def _available_xcodes_impl(ctx):
    extra_aliases_by_label = {}
    for alias, targets in ctx.attr.aliases.items():
        for target in targets:
            label = target[XcodeVersionRuleInfo].label
            extra_aliases_by_label.setdefault(label, []).append(alias)

    available_versions = [
        _merge_aliases(target[XcodeVersionRuleInfo], extra_aliases_by_label)
        for target in ctx.attr.versions
    ]
    default_version = _merge_aliases(
        ctx.attr.default[XcodeVersionRuleInfo],
        extra_aliases_by_label,
    )

    return [
        AvailableXcodesInfo(
            available_versions = available_versions,
            default_version = default_version,
        ),
    ]

available_xcodes = rule(
    attrs = {
        "aliases": attr.label_list_dict(
            allow_empty = True,
            default = {},
            doc = """\
A dictionary mapping alias strings to `xcode_version` targets. These aliases are
merged with any aliases declared directly on the referenced `xcode_version`
targets.
""",
            providers = [[XcodeVersionRuleInfo]],
        ),
        "default": attr.label(
            doc = "The default Xcode version for this platform.",
            mandatory = True,
            providers = [[XcodeVersionRuleInfo]],
        ),
        "versions": attr.label_list(
            doc = "The Xcode versions that are available on this platform.",
            providers = [[XcodeVersionRuleInfo]],
        ),
    },
    doc = """\
Two targets of this rule can be depended on by an `xcode_config` rule instance
to indicate the remotely and locally available Xcode versions. This allows
selection of an official Xcode version from the collectively available Xcodes.
        """,
    implementation = _available_xcodes_impl,
    provides = [AvailableXcodesInfo],
)
