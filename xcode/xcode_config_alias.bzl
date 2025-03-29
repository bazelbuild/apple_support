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

"""Implementation of the `xcode_config_alias` build rule.

This rule is an alias to the `xcode_config` rule currently in use, which in turn
depends on the current configuration; in particular, the value of the
`--xcode_version_config`.

This is intentionally undocumented for users; the workspace is expected to
contain exactly one instance of this rule under `@bazel_tools//tools/osx` and
people who want to get data this rule provides should depend on that one.
"""

load("@bazel_features//:features.bzl", "bazel_features")
load(
    "@build_bazel_apple_support//xcode/private:providers.bzl",
    "XcodeVersionPropertiesInfo",
)

visibility("public")

def _xcode_config_alias_impl(ctx):
    # TODO: remove when we test with Bazel 8+
    if not bazel_features.apple.xcode_config_migrated:
        fail("This rule is not available on the current Bazel version")

    xcode_config = ctx.attr._xcode_config
    return [
        xcode_config[XcodeVersionPropertiesInfo],
        # TODO: b/335817541 - At this time, there is still one place in the
        # Bazel Starlark built-in code that relies on this specific provider --
        # the code in `objc/compilation_support.bzl` that registers the
        # `ObjcBinarySymbolStrip` action. Until that code is removed or updated,
        # we must make sure to always return this provider. However, we should
        # also return a newer, modernized provider, and have non-builtin
        # Starlark clients migrate to that provider ASAP.
        xcode_config[apple_common.XcodeVersionConfig],
    ]

xcode_config_alias = rule(
    attrs = {
        "_xcode_config": attr.label(
            default = configuration_field(
                fragment = "apple",
                name = "xcode_config_label",
            ),
        ),
    },
    fragments = ["apple"],
    implementation = _xcode_config_alias_impl,
)
