#!/bin/bash

set -euo pipefail

cd "$(xcode-select -p)"

echo 'module "crosstool" [system] {'

find .. -type f \( -name "*.h" -o -name "*.def" -o -path "*/c++/*" \) \
  | LANG=C sort -u | while read -r header; do
    echo "  textual header \"${header}\""
  done

echo "}"
