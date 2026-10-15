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

"""# Minimum Xcode version conditions

Use `xcode_version_at_least` in BUILD files to configure attributes based on the
selected Xcode version.
"""

load(
    "//xcode:providers.bzl",
    "XcodeVersionInfo",
)

visibility("public")

_XcodeVersionAtLeastInfo = provider(
    doc = "Internal provider tracking metadata for an `_xcode_version_at_least_flag` target.",
    fields = {
        "flag_label": "The `Label` of this `_xcode_version_at_least_flag` target.",
        "minimum_xcode_version": "The `minimum_xcode_version` string configured on the target.",
        "required_flags": "A `depset` of `Label`s for all `_flag` targets required by this target and its transitive `after` chain.",
        "setting_label": "The `Label` of the companion `config_setting` target.",
    },
)

def _xcode_version_at_least_flag_impl(ctx):
    """Implementation of the `_xcode_version_at_least_flag` rule."""
    minimum_xcode_version = apple_common.dotted_version(
        ctx.attr.minimum_xcode_version,
    )
    setting_label = ctx.label.relative(":" + ctx.attr.setting_name)
    configured_flag_labels = {
        flag_target.label: True
        for flag_target in ctx.attr.configured_flags
    }
    configured_flag_labels[ctx.label] = True

    transitive_flag_depsets = []
    for lower_flag in ctx.attr.after:
        lower_info = lower_flag[_XcodeVersionAtLeastInfo]
        lower_minimum = apple_common.dotted_version(
            lower_info.minimum_xcode_version,
        )
        if minimum_xcode_version < lower_minimum:
            fail(
                (
                    "xcode_version_at_least '{name}' (minimum_xcode_version = '{min_ver}') " +
                    "has a lower minimum_xcode_version than '{lower_name}' " +
                    "(minimum_xcode_version = '{lower_min_ver}') in `after`. " +
                    "Configure `after = [\"{name_ref}\"]` on '{lower_name}' instead so the " +
                    "higher-version target refines the lower-version target."
                ).format(
                    lower_min_ver = lower_info.minimum_xcode_version,
                    lower_name = lower_info.setting_label,
                    min_ver = ctx.attr.minimum_xcode_version,
                    name = setting_label,
                    name_ref = ":" + ctx.attr.setting_name,
                ),
            )
        if minimum_xcode_version == lower_minimum:
            fail(
                (
                    "xcode_version_at_least '{name}' (minimum_xcode_version = '{min_ver}') " +
                    "and '{lower_name}' (minimum_xcode_version = '{lower_min_ver}') in `after` " +
                    "specify equivalent minimum Xcode versions. Use a single " +
                    "`xcode_version_at_least` target for this version, or configure distinct " +
                    "`minimum_xcode_version` values with `after` set on the higher-version target."
                ).format(
                    lower_min_ver = lower_info.minimum_xcode_version,
                    lower_name = lower_info.setting_label,
                    min_ver = ctx.attr.minimum_xcode_version,
                    name = setting_label,
                ),
            )
        for required_flag_label in lower_info.required_flags.to_list():
            if required_flag_label not in configured_flag_labels:
                fail(
                    (
                        "xcode_version_at_least '{name}' is missing transitive `after` condition " +
                        "from '{lower_name}'. Declare lower-version `xcode_version_at_least` " +
                        "targets before higher-version targets in the BUILD file, or list all " +
                        "lower-version targets explicitly in `after`."
                    ).format(
                        lower_name = lower_info.setting_label,
                        name = setting_label,
                    ),
                )
        transitive_flag_depsets.append(lower_info.required_flags)

    required_flags = depset(
        direct = [ctx.label],
        transitive = transitive_flag_depsets,
    )
    xcode_config = ctx.attr._xcode_config[XcodeVersionInfo]
    xcode_version = xcode_config.xcode_version()
    matches = bool(xcode_version and xcode_version >= minimum_xcode_version)

    return [
        config_common.FeatureFlagInfo(value = str(matches)),
        _XcodeVersionAtLeastInfo(
            flag_label = ctx.label,
            minimum_xcode_version = ctx.attr.minimum_xcode_version,
            required_flags = required_flags,
            setting_label = setting_label,
        ),
    ]

_xcode_version_at_least_flag = rule(
    implementation = _xcode_version_at_least_flag_impl,
    attrs = {
        "after": attr.label_list(
            doc = "Companion `_flag` targets for lower-version `xcode_version_at_least` targets.",
            providers = [_XcodeVersionAtLeastInfo],
        ),
        "configured_flags": attr.label_list(
            doc = "All `_flag` targets included in the companion `config_setting`'s `flag_values`.",
        ),
        "minimum_xcode_version": attr.string(
            doc = """\
The minimum Xcode version to match (inclusive), such as `"26.4"`, `"26.4.1"`,
or `"27.0.0.27A5228h"`.
""",
            mandatory = True,
        ),
        "setting_name": attr.string(
            doc = "The name of the companion `config_setting` target.",
            mandatory = True,
        ),
        "_xcode_config": attr.label(
            default = "//xcode:version_config",
        ),
    },
)

def _flag_target_label(label):
    """Returns the `_flag` target label corresponding to an `xcode_version_at_least` target."""
    if not label.startswith(":") and not label.startswith("//") and not label.startswith("@"):
        label = ":" + label
    return label + "_flag"

def _local_target_name(label):
    """Returns the local target name if `label` refers to the current package, or `None`."""
    if label.startswith("//") or label.startswith("@"):
        return None
    if label.startswith(":"):
        return label[1:]
    return label

def xcode_version_at_least(
        *,
        name,
        minimum_xcode_version,
        after = None,
        visibility = None,
        **kwargs):
    """Creates a `config_setting` target that matches when Xcode is at least `minimum_xcode_version`.

    The condition compares the resolved Xcode version, including when Xcode is
    selected by default without an explicit `--xcode_version` flag. It does not
    match if the resolved configuration has no Xcode version.

    For example, enable a definition with Xcode 26.4 or newer:

    ```starlark
    load("@apple_support//xcode:xcode_version_at_least.bzl", "xcode_version_at_least")
    load("@rules_cc//cc:cc_library.bzl", "cc_library")

    xcode_version_at_least(
        name = "xcode_26_4_or_newer",
        minimum_xcode_version = "26.4",
    )

    cc_library(
        name = "example",
        srcs = ["example.cc"],
        defines = select({
            ":xcode_26_4_or_newer": ["HAS_XCODE_26_4"],
            "//conditions:default": [],
        }),
    )
    ```

    When multiple thresholds appear in the same `select()`, use `after` to make
    the higher threshold specialize the lower one. Continuing the example above:

    ```starlark
    xcode_version_at_least(
        name = "xcode_27_or_newer",
        minimum_xcode_version = "27",
        after = [":xcode_26_4_or_newer"],
    )

    cc_library(
        name = "versioned_example",
        srcs = ["example.cc"],
        defines = select({
            ":xcode_27_or_newer": ["XCODE_LEVEL=27"],
            ":xcode_26_4_or_newer": ["XCODE_LEVEL=26"],
            "//conditions:default": ["XCODE_LEVEL=0"],
        }),
    )
    ```

    With Xcode 27 or newer, both conditions match, but the more specialized
    `xcode_27_or_newer` branch wins. Without `after`, different values for these
    overlapping conditions would make the `select()` ambiguous.

    Declare lower thresholds before higher thresholds and use local target names
    or `:name` labels to inherit a same-package `after` chain transitively. For
    cross-package or fully qualified references, list every lower threshold in
    the chain explicitly. Each threshold must be strictly higher than those in
    its `after` list.

    Args:
        name: The name of the `config_setting` target to create. A companion
            feature flag target named `<name>_flag` will also be created.
        minimum_xcode_version: The minimum Xcode version to match (inclusive),
            such as `"26.4"`, `"26.4.1"`, or `"27.0.0.27A5228h"`.
        after: An optional list of lower-version `xcode_version_at_least` target
            names or labels that this condition should refine when used together
            in the same `select()` expression. If a referenced target is in the
            same package, any lower thresholds it already refines are inherited
            transitively.
        visibility: The visibility of the generated targets.
        **kwargs: Additional keyword arguments (such as `tags` or
            `constraint_values`) forwarded to `native.config_setting`. `tags` is
            also forwarded to the companion `<name>_flag` target.
    """
    flag_name = name + "_flag"
    tags = kwargs.get("tags")
    flag_values = dict(kwargs.pop("flag_values", None) or {})
    after_flag_labels = []

    if after:
        if type(after) == type(""):
            fail("`after` must be a list of target names or labels, got a string.")
        for lower_label in after:
            lower_flag_label = _flag_target_label(lower_label)
            after_flag_labels.append(lower_flag_label)
            flag_values[lower_flag_label] = "True"
            local_name = _local_target_name(lower_label)
            if not local_name:
                continue

            existing_setting = native.existing_rule(local_name)
            if not existing_setting or not existing_setting.get("flag_values"):
                continue

            for inherited_flag, inherited_value in existing_setting.get("flag_values").items():
                flag_values[inherited_flag] = inherited_value

    _xcode_version_at_least_flag(
        name = flag_name,
        after = after_flag_labels,
        configured_flags = flag_values.keys(),
        minimum_xcode_version = minimum_xcode_version,
        setting_name = name,
        tags = tags,
        visibility = visibility,
    )

    flag_values[":" + flag_name] = "True"

    native.config_setting(
        name = name,
        flag_values = flag_values,
        visibility = visibility,
        **kwargs
    )
