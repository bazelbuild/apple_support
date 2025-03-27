package(default_visibility = ["//visibility:public"])

load("@build_bazel_apple_support//configs:platforms.bzl", "APPLE_PLATFORMS_CONSTRAINTS")
load(":cc_toolchain_config.bzl", "cc_toolchain_config")
load(":universal_exec_tool.bzl", "force_exec", "universal_exec_tool")

_APPLE_ARCHS = APPLE_PLATFORMS_CONSTRAINTS.keys()

CC_TOOLCHAINS = [(
    cpu + "|clang",
    ":cc-compiler-" + cpu,
) for cpu in _APPLE_ARCHS] + [(
    cpu,
    ":cc-compiler-" + cpu,
) for cpu in _APPLE_ARCHS] + [
    ("k8|clang", ":cc-compiler-darwin_x86_64"),
    ("darwin|clang", ":cc-compiler-darwin_x86_64"),
    ("k8", ":cc-compiler-darwin_x86_64"),
    ("darwin", ":cc-compiler-darwin_x86_64"),
]

cc_library(
    name = "link_extra_lib",
)

cc_library(
    name = "malloc",
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
        "cc_wrapper.sh.tpl",
        ":exec_wrapped_clang",
    ],
    outs = ["cc_wrapper.sh"],
    cmd = """
sed \
  -e 's|%{cc}|$(location //:exec_wrapped_clang)|' \
  $(location //:cc_wrapper.sh.tpl) \
  > $@
chmod +x $@
""",
)

force_exec(
    name = "exec_cc_wrapper",
    target = ":exec_cc_wrapper.target_config",
)


filegroup(
    name = "empty",
    srcs = [],
)

cc_toolchain_suite(
    name = "toolchain",
    toolchains = dict(CC_TOOLCHAINS),
)

filegroup(
    name = "modulemap",
    srcs = [
%{layering_check_modulemap}
    ],
)

filegroup(
    name = "tools",
    srcs = [
        ":exec_cc_wrapper",
        ":exec_libtool",
        ":exec_wrapped_clang",
        ":exec_wrapped_clang_pp",
        ":modulemap",
    ],
)

[
    cc_toolchain(
        name = "cc-compiler-" + arch,
        all_files = ":tools",
        ar_files = ":tools",
        as_files = ":tools",
        compiler_files = ":tools",
        dwp_files = ":empty",
        linker_files = ":tools",
        objcopy_files = ":empty",
        strip_files = ":tools",
        supports_header_parsing = 1,
        supports_param_files = 1,
        toolchain_config = arch,
        toolchain_identifier = arch,
        module_map = %{placeholder_modulemap},
    )
    for arch in _APPLE_ARCHS
]

[
    cc_toolchain_config(
        name = arch,
        cpu = arch,
        features = [
%{features}
        ],
        cc_wrapper = ":exec_cc_wrapper",
        cxx_builtin_include_directories = [
%{cxx_builtin_include_directories}
        ],
        libtool = ":exec_libtool",
        tool_paths_overrides = {%{tool_paths_overrides}},
        module_map = ":modulemap",
        wrapped_clang = ":exec_wrapped_clang",
        wrapped_clang_pp = ":exec_wrapped_clang_pp",
    )
    for arch in _APPLE_ARCHS
]
