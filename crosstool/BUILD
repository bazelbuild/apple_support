load("@build_bazel_apple_support//rules:apple_genrule.bzl", "apple_genrule")
load(":universal_exec_tool.bzl", "force_exec", "universal_exec_tool")

package(default_visibility = ["//visibility:public"])

# Files which shouldn't be publicly visible and dependencies of all objc_* or ios_* rules should be excluded.
exports_files(glob(
    ["**"],
))

apple_genrule(
    name = "generate_layering_check_modulemap",
    outs = ["layering_check.modulemap"],
    cmd = "$(location generate-modulemap.sh) > $(OUTS)",
    tags = ["manual"],
    tools = ["generate-modulemap.sh"],
)

universal_exec_tool(
    name = "exec_wrapped_clang",
    srcs = ["wrapped_clang.cc"],
    out = "wrapped_clang",
)

universal_exec_tool(
    name = "exec_wrapped_clang_pp",
    srcs = ["wrapped_clang.cc"],
    out = "wrapped_clang_pp",
)

universal_exec_tool(
    name = "exec_libtool",
    srcs = ["libtool.cc"],
    out = "libtool",
)

genrule(
    name = "exec_cc_wrapper.target_config",
    srcs = [
        "osx_cc_wrapper.sh.tpl",
        ":exec_wrapped_clang",
    ],
    outs = ["cc_wrapper.sh"],
    cmd = """
sed \
  -e 's|%{cc}|$(location :exec_wrapped_clang)|' \
  $(location :osx_cc_wrapper.sh.tpl) \
  > $@
chmod +x $@
""",
)

force_exec(
    name = "exec_cc_wrapper",
    target = ":exec_cc_wrapper.target_config",
)

# TODO: Remove when we drop bazel 6.x
filegroup(
    name = "xcrunwrapper",
    srcs = [":xcrunwrapper.sh"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
