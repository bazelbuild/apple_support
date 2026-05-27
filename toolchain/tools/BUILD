load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")

cc_tool_map(
    name = "tools",
    tools = {
        "@rules_cc//cc/toolchains/actions:ar_actions": ":libtool_tool",
        "@rules_cc//cc/toolchains/actions:assembly_actions": ":clang_tool",
        "@rules_cc//cc/toolchains/actions:c_compile_actions": ":clang_tool",
        "@rules_cc//cc/toolchains/actions:cpp_compile": ":clangpp_tool",  # TODO: Switch to cpp_compile_actions
        "@rules_cc//cc/toolchains/actions:cpp_module_compile": ":clang_tool",  # TODO: switch to clangpp_tool?
        "@rules_cc//cc/toolchains/actions:cpp_header_parsing": ":clang_tool",  # TODO: Switch to clangpp_tool?
        "@rules_cc//cc/toolchains/actions:objcpp_compile": ":clangpp_tool",
        "@rules_cc//cc/toolchains/actions:linkstamp_compile": ":clang_tool",  # TODO: switch to clangpp_tool?
        "@rules_cc//cc/toolchains/actions:cpp_link_dynamic_library": ":clang_tool",  # TODO: switch to clangpp_tool?
        "@rules_cc//cc/toolchains/actions:cpp_link_executable": ":clang_tool",  # TODO: switch to clangpp_tool?
        "@rules_cc//cc/toolchains/actions:objc_compile": ":clang_tool",
        "@rules_cc//cc/toolchains/actions:objc_executable": ":clang_tool",  # TODO: This should be the same as the other link actions
        "@rules_cc//cc/toolchains/actions:strip": ":strip_tool",
        "@rules_cc//cc/toolchains/actions:llvm_profdata": ":llvm_profdata_tool",
        "@rules_cc//cc/toolchains/actions:llvm_cov": ":llvm_cov_tool",
    },
    visibility = ["//:__subpackages__"],
)

cc_tool(
    name = "clang_tool",
    src = "//crosstool:exec_wrapped_clang",
    execution_requirements = ["//toolchain:xcode_execution_info"],
)

cc_tool(
    name = "clangpp_tool",
    src = "//crosstool:exec_wrapped_clang_pp",
    execution_requirements = ["//toolchain:xcode_execution_info"],
)

cc_tool(
    name = "libtool_tool",
    src = "//crosstool:exec_libtool",
    execution_requirements = ["//toolchain:xcode_execution_info"],
)

cc_tool(
    name = "strip_tool",
    src = "//crosstool:exec_strip",
    execution_requirements = ["//toolchain:xcode_execution_info"],
)

cc_tool(
    name = "llvm_profdata_tool",
    src = "//crosstool:exec_llvm_profdata",
    execution_requirements = ["//toolchain:xcode_execution_info"],
)

cc_tool(
    name = "llvm_cov_tool",
    src = "//crosstool:exec_llvm_cov",
    execution_requirements = ["//toolchain:xcode_execution_info"],
)
