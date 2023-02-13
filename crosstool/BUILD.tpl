package(default_visibility = ["//visibility:public"])

OSX_TOOLS_NON_DEVICE_ARCHS = [
    "darwin_x86_64",
    "darwin_arm64",
    "darwin_arm64e",
    "ios_i386",
    "ios_x86_64",
    "ios_sim_arm64",
    "watchos_arm64",
    "watchos_i386",
    "watchos_x86_64",
    "tvos_x86_64",
    "tvos_sim_arm64",
]

OSX_TOOLS_ARCHS = [
    "ios_armv7",
    "ios_arm64",
    "ios_arm64e",
    "watchos_armv7k",
    "watchos_arm64_32",
    "tvos_arm64",
] + OSX_TOOLS_NON_DEVICE_ARCHS

load(":cc_toolchain_config.bzl", "cc_toolchain_config")

CC_TOOLCHAINS = [(
    cpu + "|clang",
    ":cc-compiler-" + cpu,
) for cpu in OSX_TOOLS_ARCHS] + [(
    cpu,
    ":cc-compiler-" + cpu,
) for cpu in OSX_TOOLS_ARCHS] + [
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

filegroup(
    name = "empty",
    srcs = [],
)

filegroup(
    name = "cc_wrapper",
    srcs = ["cc_wrapper.sh"],
)

cc_toolchain_suite(
    name = "toolchain",
    toolchains = dict(CC_TOOLCHAINS),
)

[
    filegroup(
        name = "osx_tools_" + arch,
        srcs = [
            ":cc_wrapper",
            ":libtool",
            ":libtool_check_unique",
            ":make_hashed_objlist.py",
            ":wrapped_clang",
            ":wrapped_clang_pp",
            ":xcrunwrapper.sh",
        ],
    )
    for arch in OSX_TOOLS_ARCHS
]

[
    apple_cc_toolchain(
        name = "cc-compiler-" + arch,
        all_files = ":osx_tools_" + arch,
        ar_files = ":osx_tools_" + arch,
        as_files = ":osx_tools_" + arch,
        compiler_files = ":osx_tools_" + arch,
        dwp_files = ":empty",
        linker_files = ":osx_tools_" + arch,
        objcopy_files = ":empty",
        strip_files = ":osx_tools_" + arch,
        supports_param_files = 1,
        toolchain_config = arch,
        toolchain_identifier = arch,
    )
    for arch in OSX_TOOLS_ARCHS
]

[
    cc_toolchain_config(
        name = arch,
        compiler = "clang",
        cpu = arch,
        cxx_builtin_include_directories = [
%{cxx_builtin_include_directories}
        ],
        tool_paths_overrides = {%{tool_paths_overrides}},
    )
    for arch in OSX_TOOLS_ARCHS
]
