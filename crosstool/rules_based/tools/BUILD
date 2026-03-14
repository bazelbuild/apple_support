load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")

# TODO: These should come dynamically through xcode_config.execution_info()
_TAGS = [
    "requires-darwin",
    "supports-xcode-requirements-set",
]

cc_tool_map(
    name = "tools",
    tools = {
        "@rules_cc//cc/toolchains/actions:ar_actions": ":libtool_tool",
        "@rules_cc//cc/toolchains/actions:assembly_actions": ":clang_tool",
        "@rules_cc//cc/toolchains/actions:c_compile_actions": ":clang_tool",
        "@rules_cc//cc/toolchains/actions:cpp_compile": ":clangpp_tool",  # TODO: Switch to cpp_compile_actions
        "@rules_cc//cc/toolchains/actions:cpp_module_compile": ":clangpp_tool",
        "@rules_cc//cc/toolchains/actions:cpp_header_parsing": ":clangpp_tool",
        "@rules_cc//cc/toolchains/actions:objcpp_compile": ":clangpp_tool",
        "@rules_cc//cc/toolchains/actions:linkstamp_compile": ":clangpp_tool",
        "@rules_cc//cc/toolchains/actions:cpp_link_dynamic_library": ":cc_wrapper_tool",
        "@rules_cc//cc/toolchains/actions:cpp_link_executable": ":cc_wrapper_tool",
        "@rules_cc//cc/toolchains/actions:objc_compile": ":clang_tool",
        "@rules_cc//cc/toolchains/actions:objc_executable": ":clang_tool",  # TODO: This should be the same as the other link actions
        "@rules_cc//cc/toolchains/actions:objc_fully_link": ":libtool_tool",
        "@rules_cc//cc/toolchains/actions:strip": ":strip_tool",
    },
    visibility = ["//crosstool:__subpackages__"],
)

cc_tool(
    name = "clang_tool",
    src = "//crosstool:exec_wrapped_clang",
    tags = _TAGS,
)

cc_tool(
    name = "clangpp_tool",
    src = "//crosstool:exec_wrapped_clang_pp",
    tags = _TAGS,
)

cc_tool(
    name = "cc_wrapper_tool",
    src = "//crosstool:exec_cc_wrapper",
    data = [
        "//crosstool:exec_wrapped_clang",
    ],
    tags = _TAGS,
)

cc_tool(
    name = "libtool_tool",
    src = "//crosstool:exec_libtool",
    tags = _TAGS,
)

cc_tool(
    name = "strip_tool",
    src = "//crosstool:exec_strip",
    tags = _TAGS,
)
