#!/bin/bash
#
# Copyright 2016 The Bazel Authors. All rights reserved.
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
#

function print_message_and_exit() {
  echo $1 >&2; exit 1;
}

if type rlocation >&/dev/null; then
  # If rlocation is defined, use it to look up data-dependencies.
  # Load the unit test framework
  source "$(rlocation build_bazel_apple_support/test/shell/unittest.bash)" \
    || print_message_and_exit "unittest.bash not found!"
  # Load the test environment
  source "$(rlocation build_bazel_apple_support/test/shell/testenv.sh)" \
    || print_message_and_exit "testenv.sh not found!"
else
  # If rlocation is undefined, we are probably running under Blaze.
  # Assume the existence of a runfiles tree.

  CURRENT_SCRIPT=${BASH_SOURCE[0]}
  # Go to the directory where the script is running
  cd "$(dirname ${CURRENT_SCRIPT})" \
    || print_message_and_exit "Unable to access $(dirname ${CURRENT_SCRIPT})"

  DIR=$(pwd)
  # Load the unit test framework
  source "$DIR/unittest.bash" || print_message_and_exit "unittest.bash not found!"
  # Load the test environment
  source "$DIR/testenv.sh" || print_message_and_exit "testenv.sh not found!"
fi

# inplace-sed: a version of sed -i that actually works on Linux and Darwin.
# https://unix.stackexchange.com/questions/92895
# https://stackoverflow.com/questions/5694228
function inplace-sed() {
  if [ $(uname) = "Darwin" ]; then
    sed -i "" "$@"
  else
    sed -i "$@"
  fi
}
