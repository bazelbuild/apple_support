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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//crosstool:setup_internal.bzl", "apple_cc_autoconf", "apple_cc_autoconf_toolchains")

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g., `git_repository`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

# buildifier: disable=unnamed-macro
def _apple_cc_configure():
    apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")
    apple_cc_autoconf(name = "local_config_apple_cc")
    native.register_toolchains(
        # Use register_toolchain's target pattern expansion to register all toolchains in the package.
        "@local_config_apple_cc_toolchains//:all",
    )

# buildifier: disable=unnamed-macro
def apple_support_dependencies():
    """Fetches repository dependencies of the `apple_support` workspace.

    Users should call this macro in their `WORKSPACE` to ensure that all of the
    dependencies of the Swift rules are downloaded and that they are isolated from
    changes to those dependencies.
    """
    _maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
        ],
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
    )

    _maybe(
        http_archive,
        name = "platforms",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.9/platforms-0.0.9.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.9/platforms-0.0.9.tar.gz",
        ],
        sha256 = "5eda539c841265031c2f82d8ae7a3a6490bd62176e0c038fc469eabf91f6149b",
    )

    _maybe(
        http_archive,
        name = "bazel_features",
        sha256 = "2da0aaccbd725ad61f4e35d6d75ed421bf73ec1de167458b00ffecef3cd78f6d",
        strip_prefix = "bazel_features-1.27.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.27.0/bazel_features-v1.27.0.tar.gz",
    )

    _maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "472ddca8cec1e64ad78e4f0cabbec55936a3baddbe7bef072764ca91504bd523",
        strip_prefix = "rules_cc-0.2.13",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.2.13/rules_cc-0.2.13.tar.gz",
    )

    _apple_cc_configure()
