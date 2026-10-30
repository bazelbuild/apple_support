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
    "@build_bazel_apple_support//xcode/private:available_xcodes.bzl",
    _available_xcodes = "available_xcodes",
)

visibility("public")

# buildozer: disable=function-docstring-args
def available_xcodes(name, versions = None, **kwargs):
    """Creates an `available_xcodes` target.

    `versions` may be either a list of `xcode_version` target labels or a
    dictionary mapping each `xcode_version` target label to a list of alias
    strings for that version.
    """
    if type(versions) == type({}):
        version_labels = []
        aliases_dict = {}
        for label, label_aliases in versions.items():
            version_labels.append(label)
            for alias in label_aliases:
                aliases_dict.setdefault(alias, []).append(label)
        _available_xcodes(
            name = name,
            versions = version_labels,
            aliases = aliases_dict,
            **kwargs
        )
    else:
        _available_xcodes(
            name = name,
            versions = versions,
            **kwargs
        )
