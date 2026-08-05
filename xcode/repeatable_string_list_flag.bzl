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

"""A string list build setting that supports both repeating and comma-separation semantics."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

visibility("public")

def _repeatable_string_list_flag_impl(ctx):
    raw_values = ctx.build_setting_value
    unique_values = {}
    for val in raw_values:
        for part in val.split(","):
            if part:
                unique_values[part] = True
    return BuildSettingInfo(value = sorted(unique_values.keys()))

repeatable_string_list_flag = rule(
    implementation = _repeatable_string_list_flag_impl,
    build_setting = config.string_list(
        flag = True,
        repeatable = True,
    ),
    attrs = {
        "scope": attr.string(default = "universal"),
    },
    doc = "A string list build setting that supports both repeating (--flag=a --flag=b) and comma-separation (--flag=a,b).",
)
