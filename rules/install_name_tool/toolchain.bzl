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

"""Toolchain rule for providing a custom `install_name_tool` tool."""

InstallNameToolInfo = provider(
    doc = "Provides an `install_name_tool` for modifying Mach-O binaries.",
    fields = {
        "tool": "A `FilesToRunProvider` for the `install_name_tool` tool.",
        "env": "A `dict` of environment variables to set when running the tool.",
        "execution_requirements": """\
A `dict` of execution requirements for the action (e.g. `requires-darwin`).
""",
    },
)

def _install_name_tool_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            install_name_tool_info = InstallNameToolInfo(
                tool = ctx.attr.tool[DefaultInfo].files_to_run,
                env = ctx.attr.env,
                execution_requirements = ctx.attr.execution_requirements,
            ),
        ),
    ]

install_name_tool_toolchain = rule(
    attrs = {
        "tool": attr.label(
            doc = "The `install_name_tool` binary.",
            mandatory = True,
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "env": attr.string_dict(
            doc = "Additional environment variables to set when running install_name_tool.",
            default = {},
        ),
        "execution_requirements": attr.string_dict(
            doc = "Additional execution requirements for the action.",
            default = {},
        ),
    },
    doc = """\
Defines a toolchain for `install_name_tool` used to modify Mach-O binaries.
Use this to provide a custom `install_name_tool` implementation by defining an
`install_name_tool_toolchain` target and registering it as a toolchain.
""",
    implementation = _install_name_tool_toolchain_impl,
)
