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

load("@bazel_features//:features.bzl", "bazel_features")
load(
    "@build_bazel_apple_support//xcode/private:providers.bzl",
    "AvailableXcodesInfo",
    "XcodeVersionRuleInfo",
)

visibility("public")

def _available_xcodes_impl(ctx):
    # TODO: drop when requiring Bazel 8+
    if not bazel_features.apple.xcode_config_migrated:
        fail("This rule is not available on the current Bazel version")

    available_versions = [
        target[XcodeVersionRuleInfo]
        for target in ctx.attr.versions
    ]
    default_version = ctx.attr.default[XcodeVersionRuleInfo]

    return [
        AvailableXcodesInfo(
            available_versions = available_versions,
            default_version = default_version,
        ),
    ]

available_xcodes = rule(
    attrs = {
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
