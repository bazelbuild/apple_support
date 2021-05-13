# Copyright 2021 The Bazel Authors. All rights reserved.
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

"""APIs for operating on universal binaries with `lipo`."""

load(":apple_support.bzl", "apple_support")

def _create(
        *,
        actions,
        inputs,
        output,
        apple_fragment,
        xcode_config):
    """Creates a universal binary by combining other binaries.

    Args:
        actions: The `Actions` object used to register actions.
        inputs: A sequence or `depset` of `File`s that represent binaries to
            be combined. As with the `lipo` tool's `-create` command (when
            invoked without the `-arch` option) all of the architectures in
            each input file will be copied into the output file (so the inputs
            may be either single-architecture binaries or universal binaries).
        output: A `File` representing the universal binary that will be the
            output of the action.
        apple_fragment: The `apple` configuration fragment used to configure
            the action environment.
        xcode_config: The `apple_common.XcodeVersionConfig` provider used to
            configure the action environment.
    """
    if not inputs:
        fail("lipo.create requires at least one input file.")

    args = actions.args()
    args.add("-create")
    args.add_all(inputs)
    args.add("-output", output)

    apple_support.run(
        actions = actions,
        arguments = [args],
        executable = "/usr/bin/lipo",
        inputs = inputs,
        outputs = [output],
        apple_fragment = apple_fragment,
        xcode_config = xcode_config,
    )

# TODO(apple-rules-team): Add support for other mutating operations here if
# there is a need: extract, extract_family, remove, replace, thin.
lipo = struct(
    create = _create,
)
