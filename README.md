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
    sha256 = "02ac04ff0a0de1e891a1fa8839cc6a5957e3c4a80856545aa35a786d15aad108",
    url = "https://github.com/bazelbuild/apple_support/releases/download/0.9.1/apple_support.0.9.1.tar.gz",
)

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()
```
