load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("//toolchain:features.bzl", "negatable_feature")

package(default_visibility = ["//toolchain:__pkg__"])

negatable_feature(
    name = "__apple_default_warnings",
    actions = [
        "@rules_cc//cc/toolchains/actions:objc_compile",
        "@rules_cc//cc/toolchains/actions:objcpp_compile",
    ],
    args = [
        "-Werror=incompatible-sysroot",
        "-Wshorten-64-to-32",
        "-Wbool-conversion",
        "-Wconstant-conversion",
        "-Wduplicate-method-match",
        "-Wempty-body",
        "-Wenum-conversion",
        "-Wint-conversion",
        "-Wunreachable-code",
        "-Wmismatched-return-types",
        "-Wundeclared-selector",
        "-Wuninitialized",
        "-Wunused-function",
        "-Wunused-variable",
    ],
)

negatable_feature(
    name = "__apple_default_compiler_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:objc_compile",
        "@rules_cc//cc/toolchains/actions:objcpp_compile",
    ],
    args = select({
        "@platforms//os:macos": ["-DOS_MACOSX"],
        "@platforms//os:ios": ["-DOS_IOS"],
        "@platforms//os:watchos": ["-DOS_IOS"],  # NOTE: This is weird
        "@platforms//os:tvos": ["-DOS_TVOS"],
        "@platforms//os:visionos": [],
    }) + ["-fno-autolink"],
)

cc_args(
    name = "objc_executable_non_kernel_extension_flags",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = [
        "-Xlinker",
        "-objc_abi_version",
        "-Xlinker",
        "2",
    ],
    requires_any_of = ["//toolchain:not_kernel_extension"],
)

cc_args(
    name = "objc_executable_filelist_args",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = [
        "-filelist",
        "{filelist}",
    ],
    format = {"filelist": "@rules_cc//cc/toolchains/variables:filelist"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:filelist",
)

cc_args(
    name = "objc_executable_linked_binary_args",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = [
        "-o",
        "{linked_binary}",
        "LINKED_BINARY={linked_binary}",
    ],
    format = {"linked_binary": "@rules_cc//cc/toolchains/variables:linked_binary"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:linked_binary",
)

cc_args(
    name = "objc_executable_force_load_args",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = [
        "-force_load",
        "{force_load_exec_paths}",
    ],
    format = {"force_load_exec_paths": "@rules_cc//cc/toolchains/variables:force_load_exec_paths"},
    iterate_over = "@rules_cc//cc/toolchains/variables:force_load_exec_paths",
    requires_not_none = "@rules_cc//cc/toolchains/variables:force_load_exec_paths",
)

cc_args(
    name = "objc_executable_dep_linkopts",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = ["{dep_linkopts}"],
    format = {"dep_linkopts": "@rules_cc//cc/toolchains/variables:dep_linkopts"},
    iterate_over = "@rules_cc//cc/toolchains/variables:dep_linkopts",
    requires_not_none = "@rules_cc//cc/toolchains/variables:dep_linkopts",
)

cc_args(
    name = "objc_executable_attr_linkopts",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = ["-Wl,{attr_linkopts}"],
    format = {"attr_linkopts": "@rules_cc//cc/toolchains/variables:attr_linkopts"},
    iterate_over = "@rules_cc//cc/toolchains/variables:attr_linkopts",
    requires_not_none = "@rules_cc//cc/toolchains/variables:attr_linkopts",
)

negatable_feature(
    name = "__objc_executable_feature",
    custom_args = [
        ":objc_executable_non_kernel_extension_flags",
        ":objc_executable_filelist_args",
        ":objc_executable_linked_binary_args",
        ":objc_executable_force_load_args",
        ":objc_executable_dep_linkopts",
        ":objc_executable_attr_linkopts",
    ],
)

negatable_feature(
    name = "objc_link_flag",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = ["-ObjC"],
    requires_any_of = ["//toolchain:not_kernel_extension"],
)

cc_args(
    name = "objc_fully_link_default_args",
    actions = ["@rules_cc//cc/toolchains/actions:objc_fully_link"],
    args = [
        "-D",
        "-no_warning_for_no_symbols",
        "-static",
        "-arch_only",
        "{ARCH}",
    ],
    toolchains = ["//toolchain:dynamic_toolchain_info"],
)

cc_args(
    name = "objc_fully_link_output_args",
    actions = ["@rules_cc//cc/toolchains/actions:objc_fully_link"],
    args = [
        "-o",
        "{fully_linked_archive_path}",
    ],
    format = {"fully_linked_archive_path": "@rules_cc//cc/toolchains/variables:fully_linked_archive_path"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:fully_linked_archive_path",
)

cc_args(
    name = "objc_fully_link_objc_library_exec_paths",
    actions = ["@rules_cc//cc/toolchains/actions:objc_fully_link"],
    args = ["{objc_library_exec_paths}"],
    format = {"objc_library_exec_paths": "@rules_cc//cc/toolchains/variables:objc_library_exec_paths"},
    iterate_over = "@rules_cc//cc/toolchains/variables:objc_library_exec_paths",
    requires_not_none = "@rules_cc//cc/toolchains/variables:objc_library_exec_paths",
)

cc_args(
    name = "objc_fully_link_cc_library_exec_paths",
    actions = ["@rules_cc//cc/toolchains/actions:objc_fully_link"],
    args = ["{cc_library_exec_paths}"],
    format = {"cc_library_exec_paths": "@rules_cc//cc/toolchains/variables:cc_library_exec_paths"},
    iterate_over = "@rules_cc//cc/toolchains/variables:cc_library_exec_paths",
    requires_not_none = "@rules_cc//cc/toolchains/variables:cc_library_exec_paths",
)

cc_args(
    name = "objc_fully_link_imported_library_exec_paths",
    actions = ["@rules_cc//cc/toolchains/actions:objc_fully_link"],
    args = ["{imported_library_exec_paths}"],
    format = {"imported_library_exec_paths": "@rules_cc//cc/toolchains/variables:imported_library_exec_paths"},
    iterate_over = "@rules_cc//cc/toolchains/variables:imported_library_exec_paths",
    requires_not_none = "@rules_cc//cc/toolchains/variables:imported_library_exec_paths",
)

# TODO: Remove https://github.com/bazelbuild/rules_cc/pull/644
negatable_feature(
    name = "__objc_fully_link_feature",
    custom_args = [
        ":objc_fully_link_default_args",
        ":objc_fully_link_output_args",
        ":objc_fully_link_objc_library_exec_paths",
        ":objc_fully_link_cc_library_exec_paths",
        ":objc_fully_link_imported_library_exec_paths",
    ],
)
