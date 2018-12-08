#!/bin/bash
#
# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# SYNOPSIS
#   Replaces Bazel placeholder values with DEVELOPER_DIR and SDKROOT in the
#   argument list or in params files with their actual values.
#
#   This script requires the XCODE_PATH_RESOLVE_LEVEL environment variable to be
#   set to either the `args` or `args_and_files` values. When the value is
#   `args`, only the given arguments will be processed to replace instances of
#   the Bazel placeholders with DEVELOPER_DIR and SDKROOT. When the value is
#   `args_and_files`, as well as processing the args as before, if an argument
#   begins with `@`, it will be treated as a response file and the contents of
#   such file will be processed to replaced the Bazel placeholder values.
#
# USAGE
#   xcode_path_wrapper.sh <executable> <arguments...>
#
# ARGUMENTS
#   executable: The actual executable to launch.
#   arguments...: Arguments that are processed and then passed to the
#     executable.

set -eu

if [[ -z "${XCODE_PATH_RESOLVE_LEVEL:-}" ]]; then
  cat <<END

ERROR: xcode_path_wrapper.sh requires to be invoked with the \
XCODE_PATH_RESOLVE_LEVEL environment variable set to either 'args' or \
'args_and_files'

END

  exit 1
fi

# SYNOPSIS
#   Rewrites any Bazel placeholder strings in the given argument string,
#   echoing the result.
#
# USAGE
#   rewrite_argument <argument>
function rewrite_argument {
  ARG="$1"
  ARG="${ARG//__BAZEL_XCODE_DEVELOPER_DIR__/$DEVELOPER_DIR}"
  ARG="${ARG//__BAZEL_XCODE_SDKROOT__/$SDKROOT}"
  echo "$ARG"
}

# SYNOPSIS
#   Rewrites any Bazel placeholder strings in the given params file, if any.
#   If there were no substitutions to be made, the original path is echoed back
#   out; otherwise, this function echoes the path to a temporary file
#   containing the rewritten file.
#
# USAGE
#   rewrite_params_file <path>
function rewrite_params_file {
  PARAMSFILE="$1"
  if grep -qe '__BAZEL_XCODE_\(DEVELOPER_DIR\|SDKROOT\)__' "$PARAMSFILE" ; then
    NEWFILE="$(mktemp "${TMPDIR%/}/bazel_xcode_wrapper_params.XXXXXXXXXX")"
    sed \
        -e "s#__BAZEL_XCODE_DEVELOPER_DIR__#$DEVELOPER_DIR#g" \
        -e "s#__BAZEL_XCODE_SDKROOT__#$SDKROOT#g" \
        "$PARAMSFILE" > "$NEWFILE"
    echo "$NEWFILE"
  else
    # There were no placeholders to substitute, so just return the original
    # file.
    echo "$PARAMSFILE"
  fi
}

TOOLNAME="$1"
shift

ARGS=()

if [[ "$XCODE_PATH_RESOLVE_LEVEL" == "args" ]]; then

  for ARG in "$@" ; do
    ARGS+=("$(rewrite_argument "$ARG")")
  done

  exec "$TOOLNAME" "${ARGS[@]}"

elif [[ "$XCODE_PATH_RESOLVE_LEVEL" == "args_and_files" ]]; then

  # If any temporary files are created (like rewritten response files), clean
  # them up when the script exits.
  TEMPFILES=()
  trap '[[ ${#TEMPFILES[@]} -ne 0 ]] && rm "${TEMPFILES[@]}"' EXIT

  for ARG in "$@" ; do
    case "$ARG" in
    @*)
      PARAMSFILE="${ARG:1}"
      NEWFILE=$(rewrite_params_file "$PARAMSFILE")
      if [[ "$PARAMSFILE" != "$NEWFILE" ]] ; then
        TEMPFILES+=("$NEWFILE")
      fi
      ARG="@$NEWFILE"
      ;;
    *)
      ARG=$(rewrite_argument "$ARG")
      ;;
    esac
    ARGS+=("$ARG")
  done

  # We can't use `exec` here because we need to make sure the `trap` runs
  # afterward.
  "$TOOLNAME" "${ARGS[@]}"
else
  cat <<END

ERROR: Unrecognized value for XCODE_PATH_RESOLVE_LEVEL: \
"$XCODE_PATH_RESOLVE_LEVEL"

END

  exit 1
fi
