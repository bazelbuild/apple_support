#!/bin/bash

set -euo pipefail

bazel build //doc/...

cp bazel-bin/doc/apple_support.md doc/
cp bazel-bin/doc/repositories.md doc/
cp bazel-bin/doc/xcode_support.md doc/
cp bazel-bin/doc/rules.md doc/
