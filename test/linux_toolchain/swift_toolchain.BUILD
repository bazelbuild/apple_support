load("@apple_support//toolchain:cc_toolchain.bzl", "cc_toolchain")
load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")
load("@rules_cc//cc/toolchains/args:sysroot.bzl", "cc_sysroot")

filegroup(
    name = "clang_support_files",
    srcs = [
        "usr/bin/clang-21",
        "usr/bin/ld.lld",
        "usr/bin/x86_64-swift-linux-musl-clang.cfg",
        "usr/bin/x86_64-swift-linux-musl-clang++.cfg",
    ] + glob(["usr/lib/clang/21/**"]),
)

cc_tool(
    name = "clang",
    src = "usr/bin/clang",
    data = [":clang_support_files"],
)

cc_tool(
    name = "clang++",
    src = "usr/bin/clang++",
    data = [":clang_support_files"],
)

cc_tool(
    name = "llvm_ar",
    src = "usr/bin/llvm-ar",
)

cc_tool(
    name = "llvm_cov",
    src = "usr/bin/llvm-cov",
)

cc_tool(
    name = "llvm_objcopy",
    src = "usr/bin/llvm-objcopy",
)

cc_tool(
    name = "llvm_profdata",
    src = "usr/bin/llvm-profdata",
)

cc_tool_map(
    name = "tools",
    tools = {
        "@rules_cc//cc/toolchains/actions:ar_actions": ":llvm_ar",
        "@rules_cc//cc/toolchains/actions:assembly_actions": ":clang",
        "@rules_cc//cc/toolchains/actions:c_compile": ":clang",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions": ":clang++",
        "@rules_cc//cc/toolchains/actions:link_actions": ":clang++",
        "@rules_cc//cc/toolchains/actions:llvm_cov": ":llvm_cov",
        "@rules_cc//cc/toolchains/actions:llvm_profdata": ":llvm_profdata",
        "@rules_cc//cc/toolchains/actions:objcopy_embed_data": ":llvm_objcopy",
        "@rules_cc//cc/toolchains/actions:strip": ":llvm_objcopy",
    },
)

cc_sysroot(
    name = "sysroot_args",
    actions = [
        "@rules_cc//cc/toolchains/actions:compile_actions",
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    allowlist_include_directories = ["@swift_linux_sysroot//x86_64:root"],
    args = ["--target=x86_64-swift-linux-musl"],
    data = ["@swift_linux_sysroot//x86_64:directory"],
    sysroot = "@swift_linux_sysroot//x86_64:root",
)

cc_args(
    name = "link_toolchain_args",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-rtlib=compiler-rt"],
)

cc_feature(
    name = "sysroot_feature",
    args = [
        ":sysroot_args",
        ":link_toolchain_args",
    ],
    feature_name = "sysroot",
)

cc_toolchain(
    name = "cc_toolchain",
    module_map = None,
    supports_header_parsing = False,
    sysroot_feature = ":sysroot_feature",
    target = "x86_64-swift-linux-musl",
    tool_map = ":tools",
)
