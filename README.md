# Apple Support for [Bazel](https://bazel.build)

[![Build Status](https://badge.buildkite.com/6739ca70cb485ecec4ec403f4d6775269728aece4bb984127f.svg?branch=master)](https://buildkite.com/bazel/apple-support-darwin)

This repository contains helper methods that support building rules that target
Apple platforms.

## Quick setup

Add the following to your `WORKSPACE` file to add this repository as a dependency:

```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "build_bazel_apple_support",
    remote = "https://github.com/bazelbuild/apple_support.git",
    tag = "0.7.0",
)

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()
```
