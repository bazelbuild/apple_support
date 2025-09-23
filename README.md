# Apple Support for [Bazel](https://bazel.build)

This repository contains the [Apple CC toolchain](#toolchain-setup),
Apple related [platforms](platforms/BUILD) and
[constraints](constraints/BUILD) definitions, and small helper functions
for rules authors targeting Apple platforms.

If you want to build iOS, tvOS, visionOS, watchOS, or macOS apps, use
[`rules_apple`][rules_apple].

If you want to build Swift use
[`rules_swift`](https://github.com/bazelbuild/rules_swift).

See [the documentation](doc) for the helper rules provided by this
repository.

## Installation

Copy the `MODULE.bazel` or `WORKSPACE` snippets from [the releases
page](https://github.com/bazelbuild/apple_support/releases) into your
project.

## Toolchain setup

The Apple CC toolchain in this repository provides toolchains for
building for Apple platforms besides macOS. Since Bazel 7 this toolchain
is required when targeting those platforms.

The toolchain supports using a full Xcode installation or the Xcode
Command Line Tools.

### Bazel 7+ Setup

For Bazel 7+ the only setup that is required is to have `apple_support`
in your `MODULE.bazel` (even if you're not referencing it directly) or
`WORKSPACE`, which you can copy from [the releases
page](https://github.com/bazelbuild/apple_support/releases) into your
project.

If you also depend on `rules_cc`, `apple_support` must come _above_
`rules_cc` in your `MODULE.bazel` or `WORKSPACE` file because Bazel
selects toolchains based on which is registered first.

## Toolchain configuration

There are many different flags you can flip to configure how the
toolchain works. Here are some of the more commonly useful ones:

- Setting `DEVELOPER_DIR` in the environment. This is recommended so
  that the toolchain can be invalidated when the `DEVELOPER_DIR`
  changes, which ensures that toolchain binaries will be rebuilt with
  the new version of Xcode so that caches are correctly shared across
  machines.
- Setting `BAZEL_ALLOW_NON_APPLICATIONS_XCODE=1` in the environment (or
  using `--repo_env`) allows the toolchain to discover Xcode versions
  outside of the `/Applications` directory to avoid header inclusion
  errors from bazel. This is not enabled by default because
  `/Applications` is the standard directory, and this improves toolchain
  setup performance.

[rules_apple]: https://github.com/bazelbuild/rules_apple
