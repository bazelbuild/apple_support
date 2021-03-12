# Apple Support for [Bazel](https://bazel.build)

[![Build Status](https://badge.buildkite.com/6739ca70cb485ecec4ec403f4d6775269728aece4bb984127f.svg?branch=master)](https://buildkite.com/bazel/apple-support-darwin)

This repository contains helper methods that support building rules that target
Apple platforms.

## Quick setup

Add the following to your `WORKSPACE` file to add this repository as a dependency:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_apple_support",
    sha256 = "a1926bbc5bbb86d596ee1e9c307e22c9a0305053e46057cf186d015b09b3c5f2",
    url = "https://github.com/bazelbuild/apple_support/releases/download/0.9.2/apple_support.0.9.2.tar.gz",
)

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()
```
