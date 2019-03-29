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

"""Helper functions related to apple framework cleanup migration."""

def _is_post_framework_migration():
    """Determine whether bazel is pre- or post- framework infrastructure migration.

    Returns:
        Whether bazel has been updated to use the new framework infrastructure.
    """

    return hasattr(apple_common.new_objc_provider(), "static_framework_names")

framework_migration = struct(
    is_post_framework_migration = _is_post_framework_migration,
)
