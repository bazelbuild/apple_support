#!/usr/bin/env bash

set -euo pipefail

exec /usr/bin/install_name_tool "$@"
