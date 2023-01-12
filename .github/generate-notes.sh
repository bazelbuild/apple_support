#!/bin/bash

set -euo pipefail

readonly new_version=$1
readonly release_archive="apple_support.$new_version.tar.gz"

sha=$(shasum -a 256 "$release_archive" | cut -d " " -f1)

cat <<EOF
## What's Changed

TODO

This release is compatible with: TODO

### MODULE.bazel Snippet

\`\`\`bzl
bazel_dep(name = "apple_support", version = "$new_version", repo_name = "build_bazel_apple_support")
\`\`\`

### Workspace Snippet

\`\`\`bzl
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_apple_support",
    sha256 = "$sha",
    url = "https://github.com/bazelbuild/apple_support/releases/download/$new_version/apple_support.$new_version.tar.gz",
)

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()
\`\`\`
EOF
