"""Toolchain definition to provide Lipo tool location.

Usage:

    load("@build_bazel_apple_support//toolchain/lipo:lipo_toolchain.bzl", "lipo_toolchain")

    lipo_toolchain(
        name = "_lipo_toolchain",
        lipo = ":lipo",
    )

    toolchain(
        name = "lipo_toolchain",
        toolchain = ":_lipo_toolchain",
        toolchain_type = "@build_bazel_apple_support//toolchain/lipo:toolchain_type",
        exec_compatible_with = [
            "@platforms//os:macos",
        ],
        target_compatible_with = [
            "@platforms//os:macos",
        ],
    )

"""

Info = provider(
    fields = ["lipo"],
    doc = "Tools info to locate xcode tools",
)

def _lipo_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        info = Info(
            lipo = ctx.file.lipo,
        ),
    )
    return [toolchain_info]

lipo_toolchain = rule(
    doc = "Toolchain rule to provide Lipo tool location.",
    implementation = _lipo_toolchain_impl,
    attrs = {
        "lipo": attr.label(
            doc = "a label to lipo tool.",
            allow_single_file = True,
        ),
    },
)
