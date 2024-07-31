package(default_visibility = ["//visibility:public"])

load("@build_bazel_apple_support//configs:platforms.bzl", "APPLE_PLATFORMS_CONSTRAINTS")
load(":cc_toolchain_config.bzl", "cc_toolchain_config")

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

# TODO: Extract to macro?
genrule(
    name = "exec_wrapped_clang",
    srcs = ["wrapped_clang.cc"],
    outs = ["wrapped_clang"],
    cmd = """
env -i \
  DEVELOPER_DIR=$$DEVELOPER_DIR \
  xcrun \
    --sdk macosx \
    clang \
      -mmacosx-version-min=10.15 \
      -std=c++17 \
      -lc++ \
      -arch arm64 \
      -arch x86_64 \
      -Wl,-no_adhoc_codesign \
      -Wl,-no_uuid \
      -O3 \
      -o $@ \
      $(SRCS)

env -i \
  codesign \
    --identifier $@ \
    --force \
    --sign - \
    $@
""",
)

## TODO: Symlink somehow
genrule(
    name = "exec_wrapped_clang_pp",
    srcs = ["wrapped_clang.cc"],
    outs = ["wrapped_clang_pp"],
    cmd = """
env -i \
  DEVELOPER_DIR=$$DEVELOPER_DIR \
  xcrun \
    --sdk macosx \
    clang \
      -mmacosx-version-min=10.15 \
      -std=c++17 \
      -lc++ \
      -arch arm64 \
      -arch x86_64 \
      -Wl,-no_adhoc_codesign \
      -Wl,-no_uuid \
      -O3 \
      -o $@ \
      $(SRCS)

env -i \
  codesign \
    --identifier $@ \
    --force \
    --sign - \
    $@
""",
)

genrule(
    name = "exec_libtool_check_unique",
    srcs = ["libtool_check_unique.cc"],
    outs = ["libtool_check_unique"],
    cmd = """
env -i \
  DEVELOPER_DIR=$$DEVELOPER_DIR \
  xcrun \
    --sdk macosx \
    clang \
      -mmacosx-version-min=10.15 \
      -std=c++17 \
      -lc++ \
      -arch arm64 \
      -arch x86_64 \
      -Wl,-no_adhoc_codesign \
      -Wl,-no_uuid \
      -O3 \
      -o $@ \
      $(SRCS)

env -i \
  codesign \
    --identifier $@ \
    --force \
    --sign - \
    $@
""",
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

filegroup(
    name = "modulemap",
    srcs = [
%{layering_check_modulemap}
    ],
)

[
    filegroup(
        name = "osx_tools_" + arch,
        srcs = [
            ":cc_wrapper",
            ":libtool",
            ":exec_libtool_check_unique",
            ":make_hashed_objlist.py",
            ":modulemap",
            ":exec_wrapped_clang",
            ":exec_wrapped_clang_pp",
            ":xcrunwrapper.sh",
        ],
    )
    for arch in _APPLE_ARCHS
]

[
    cc_toolchain(
        name = "cc-compiler-" + arch,
        all_files = ":osx_tools_" + arch,
        ar_files = ":osx_tools_" + arch,
        as_files = ":osx_tools_" + arch,
        compiler_files = ":osx_tools_" + arch,
        dwp_files = ":empty",
        linker_files = ":osx_tools_" + arch,
        objcopy_files = ":empty",
        strip_files = ":osx_tools_" + arch,
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
        cxx_builtin_include_directories = [
%{cxx_builtin_include_directories}
        ],
        libtool_check_unique = ":exec_libtool_check_unique",
        tool_paths_overrides = {%{tool_paths_overrides}},
        module_map = ":modulemap",
        wrapped_clang = ":exec_wrapped_clang",
        wrapped_clang_pp = ":exec_wrapped_clang_pp",
    )
    for arch in _APPLE_ARCHS
]
