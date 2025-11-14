#!/bin/bash

set -euo pipefail

readonly new_version=$1

cat <<EOF
## What's Changed

TODO

This release is compatible with: TODO

### MODULE.bazel Snippet

\`\`\`bzl
bazel_dep(name = "apple_support", version = "$new_version", repo_name = "build_bazel_apple_support")
\`\`\`
EOF
