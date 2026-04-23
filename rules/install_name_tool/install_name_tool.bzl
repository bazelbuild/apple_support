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

"""Rule for modifying Mach-O binaries with install_name_tool."""

_TOOLCHAIN_TYPE = "//rules/install_name_tool:toolchain_type"

def _install_name_tool_impl(ctx):
    args = ctx.actions.args()
    if ctx.attr.install_name:
        args.add("-id", ctx.attr.install_name)

    for rpath in ctx.attr.add_rpath:
        args.add("-add_rpath", rpath)

    for rpath in ctx.attr.prepend_rpath:
        args.add("-prepend_rpath", rpath)

    for rpath in ctx.attr.delete_rpath:
        args.add("-delete_rpath", rpath)

    for old, new in ctx.attr.change_library.items():
        args.add("-change")
        args.add(old)
        args.add(new)

    for old, new in ctx.attr.change_rpath.items():
        args.add("-rpath")
        args.add(old)
        args.add(new)

    if not args:
        fail("No modifications specified for install_name_tool.")

    toolchain_info = ctx.toolchains[_TOOLCHAIN_TYPE].install_name_tool_info
    output = ctx.actions.declare_file(ctx.label.name)
    args.add(output)

    ctx.actions.run_shell(
        inputs = [ctx.file.src],
        outputs = [output],
        tools = [toolchain_info.tool],
        command = "cp \"$1\" \"$2\" && chmod u+w \"$2\" && shift 2 && exec \"$@\"",
        arguments = [ctx.file.src.path, output.path, toolchain_info.tool.executable.path, args],
        mnemonic = "InstallNameTool",
        progress_message = "Editing load commands %{output}",
        env = toolchain_info.env,
        execution_requirements = toolchain_info.execution_requirements,
        use_default_shell_env = True,
    )

    return [DefaultInfo(
        files = depset([output]),
    )]

install_name_tool = rule(
    doc = """\
Modifies a Mach-O binary using `install_name_tool`.

This rule copies the input binary and applies the requested modifications to
the copy. It uses a toolchain to resolve the `install_name_tool` binary,
allowing users to provide their own implementation if needed.

Example usage:

```build
load("@build_bazel_apple_support//rules/install_name_tool:install_name_tool.bzl", "install_name_tool")

install_name_tool(
    name = "patched_lib",
    src = ":my_dylib",
    install_name = "@rpath/libfoo.dylib",
    add_rpath = ["@loader_path/../Frameworks"],
)
```
""",
    implementation = _install_name_tool_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The Mach-O binary to modify.",
        ),
        "install_name": attr.string(
            doc = "The new install name (`-id`) for the binary.",
        ),
        "add_rpath": attr.string_list(
            doc = "Rpaths to add (`-add_rpath`).",
        ),
        "prepend_rpath": attr.string_list(
            doc = "Rpaths to prepend (`-prepend_rpath`).",
        ),
        "delete_rpath": attr.string_list(
            doc = "Rpaths to delete (`-delete_rpath`).",
        ),
        "change_library": attr.string_dict(
            doc = "Library paths to change (`-change old new`). Keys are old paths, values are new paths.",
        ),
        "change_rpath": attr.string_dict(
            doc = "Rpaths to change (`-rpath old new`). Keys are old rpaths, values are new rpaths.",
        ),
    },
    toolchains = [_TOOLCHAIN_TYPE],
)
