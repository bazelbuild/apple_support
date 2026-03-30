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

"""Xcode-aware toolchain rule for providing an `install_name_tool` tool."""

load("//lib:apple_support.bzl", "apple_support")
load(":toolchain.bzl", "InstallNameToolInfo")

def _xcode_install_name_tool_toolchain_impl(ctx):
    env = dict(ctx.attr.env)
    execution_requirements = dict(ctx.attr.execution_requirements)

    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    if xcode_config:
        env.update(apple_common.apple_host_system_env(xcode_config))
        env.update(
            apple_common.target_apple_env(xcode_config, ctx.fragments.apple.single_arch_platform),
        )
        execution_requirements.update(xcode_config.execution_info())

    return [
        platform_common.ToolchainInfo(
            install_name_tool_info = InstallNameToolInfo(
                tool = ctx.attr.tool[DefaultInfo].files_to_run,
                env = env,
                execution_requirements = execution_requirements,
            ),
        ),
    ]

xcode_install_name_tool_toolchain = rule(
    attrs = apple_support.action_required_attrs() | {
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
This toolchain automatically sets environment variables and execution
requirements required to run Xcode's install_name_tool hermetically.
""",
    fragments = ["apple"],
    implementation = _xcode_install_name_tool_toolchain_impl,
)
