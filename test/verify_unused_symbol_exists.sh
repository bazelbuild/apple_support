#!/bin/bash

set -euo pipefail
set -x

readonly binary="%{binary}s"

nm "$binary" | grep addOne \
  || (echo "should find symbol addOne" >&2 && exit 1)
