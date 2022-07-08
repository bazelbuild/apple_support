# Apple Support for [Bazel](https://bazel.build)

This repository contains helper methods that support building rules that
target Apple platforms. See [the
docs](https://github.com/bazelbuild/apple_support/tree/master/doc) for
how you can use these helpers. Also see
[rules_apple](https://github.com/bazelbuild/rules_apple) and
[rules_swift](https://github.com/bazelbuild/rules_swift) for more Apple
platform rules.

## Quick setup

Add the following to your `WORKSPACE` file to add this repository as a dependency:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_apple_support",
    sha256 = "ce1042cf936540eaa7b49c4549d7cd9b6b1492acbb6e765840a67a34b8e17a97",
    url = "https://github.com/bazelbuild/apple_support/releases/download/1.1.0/apple_support.1.1.0.tar.gz",
)

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()
```
