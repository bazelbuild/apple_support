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

"""Xcode-aware toolchain rule for providing a `lipo` tool."""

load("//lib:apple_support.bzl", "apple_support")
load(":lipo_toolchain.bzl", "LipoToolchainInfo")

def _xcode_lipo_toolchain_impl(ctx):
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
            lipo_info = LipoToolchainInfo(
                lipo = ctx.attr.lipo[DefaultInfo].files_to_run,
                env = env,
                execution_requirements = execution_requirements,
            ),
        ),
    ]

xcode_lipo_toolchain = rule(
    attrs = apple_support.action_required_attrs() | {
        "lipo": attr.label(
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
binaries. This toolchain automatically sets environment variables and execution
requirements required to run Xcode's lipo hermetically.
""",
    fragments = ["apple"],
    implementation = _xcode_lipo_toolchain_impl,
)
