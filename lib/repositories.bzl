# Copyright 2018 The Bazel Authors. All rights reserved.
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

"""Definitions for handling Bazel repositories used by apple_support."""

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g., `git_repository`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if name not in native.existing_rules():
        repo_rule(name = name, **kwargs)

def apple_support_dependencies():
    """Fetches repository dependencies of the `apple_support` workspace.

    Users should call this macro in their `WORKSPACE` to ensure that all of the
    dependencies of the Swift rules are downloaded and that they are isolated from
    changes to those dependencies.
    """
    _maybe(
        git_repository,
        name = "bazel_skylib",
        remote = "https://github.com/bazelbuild/bazel-skylib.git",
        tag = "0.5.0",
    )
