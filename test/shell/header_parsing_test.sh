#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

bazel="${BAZEL:-bazel}"

"$bazel" test --announce_rc --process_headers_in_dependencies -- //test/header_parsing/...
