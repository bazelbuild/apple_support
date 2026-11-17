# Copyright 2026 The Bazel Authors. All rights reserved.
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

"""Toolchain rule for providing a custom `lipo` tool."""

LipoInfo = provider(
    doc = "Provides a `lipo` tool for creating and manipulating universal binaries.",
    fields = {
        "tool": "A `FilesToRunProvider` for the `lipo` tool.",
        "env": "A `dict` of environment variables to set when running the tool.",
        "execution_requirements": """\
A `dict` of execution requirements for the action (e.g. `requires-darwin`).
""",
    },
)

def _lipo_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            lipo_info = LipoInfo(
                tool = ctx.attr.tool[DefaultInfo].files_to_run,
                env = ctx.attr.env,
                execution_requirements = ctx.attr.execution_requirements,
            ),
        ),
    ]

lipo_toolchain = rule(
    attrs = {
        "tool": attr.label(
            doc = "The `lipo` tool binary.",
            mandatory = True,
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "env": attr.string_dict(
            doc = "Additional environment variables to set when running lipo.",
            default = {},
        ),
        "execution_requirements": attr.string_dict(
            doc = "Additional execution requirements for the action.",
            default = {},
        ),
    },
    doc = """\
Defines a toolchain for the `lipo` tool used to create and manipulate universal
binaries. Use this to provide a custom `lipo` implementation by defining a
`lipo_toolchain` target and registering it as a toolchain.
""",
    implementation = _lipo_toolchain_impl,
)
