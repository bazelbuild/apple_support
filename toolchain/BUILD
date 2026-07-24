load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:selects.bzl", "selects")
load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:args_list.bzl", "cc_args_list")
load("@rules_cc//cc/toolchains:artifacts.bzl", "cc_artifact_name_pattern")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:feature_constraint.bzl", "cc_feature_constraint")
load("@rules_cc//cc/toolchains:feature_set.bzl", "cc_feature_set")
load("@rules_cc//cc/toolchains:legacy_tool.bzl", "cc_legacy_tool")
load("@rules_cc//cc/toolchains:make_variable.bzl", "cc_make_variable")
load("@rules_cc//cc/toolchains:nested_args.bzl", "cc_nested_args")
load(":cc_toolchain.bzl", "cc_toolchain")
load(":dynamic_toolchain_info.bzl", "dynamic_toolchain_info", "xcode_execution_info")
load(":features.bzl", "enableable_feature", "negatable_feature")

package(default_visibility = ["//visibility:public"])

# Consumers can append an extra cc_args (for example with
# allowlist_absolute_include_directories for hermetic Xcodes vendored into
# external repositories) without modifying this toolchain:
#   --@apple_support//toolchain:extra_include_directories=//your:cc_args
label_flag(
    name = "extra_include_directories",
    build_setting_default = ":no_extra_include_directories",
)

cc_args(
    name = "no_extra_include_directories",
    actions = ["@rules_cc//cc/toolchains/actions:all_actions"],
)

MARKER_FEATURES = [
    "archive_param_file",
    "compile_all_modules",
    "compiler_param_file",
    "compiler_param_file_on_demand",
    "exclude_private_headers_in_module_maps",
    "gcc_quoting_for_param_files",
    "no_dotd_file",
    "no_legacy_features",
    "only_doth_headers_in_module_maps",
    "parse_headers",
    "parse_headers_as_c",
    "sanitize_pwd",
    "set_soname",
]

ENABLED_MARKERS = [
    "archive_param_file",
    "sanitize_pwd",
    "set_soname",
] + (
    ["gcc_quoting_for_param_files"] if bazel_features.cc.fixed_dsym_path_quoting else []
)

cc_feature_set(
    name = "_empty_feature_set",
    all_of = [],
)

label_flag(
    name = "extra_enabled_features",
    build_setting_default = ":_empty_feature_set",
    visibility = ["//visibility:public"],
)

label_flag(
    name = "extra_known_features",
    build_setting_default = ":_empty_feature_set",
    visibility = ["//visibility:public"],
)

# TODO: See if we really need this one
_LIMITED_COMPILE_ACTIONS = [
    "@rules_cc//cc/toolchains/actions:c_compile",
    "@rules_cc//cc/toolchains/actions:cpp_compile",
    "@rules_cc//cc/toolchains/actions:objc_compile",
    "@rules_cc//cc/toolchains/actions:objcpp_compile",
]

[
    cc_feature(
        name = name,
        feature_name = name,
    )
    for name in MARKER_FEATURES
]

cc_feature(
    name = "supports_pic",
    feature_name = "supports_pic",
)

cc_feature_set(
    name = "_marker_features",
    all_of = MARKER_FEATURES + select({
        "//configs:apple": [],
        "//conditions:default": [":supports_pic"],
    }),
)

cc_feature_set(
    name = "_enabled_markers",
    all_of = ENABLED_MARKERS + select({
        "//configs:apple": [],
        "//conditions:default": [":supports_pic"],
    }),
)

cc_feature(
    name = "dbg",
    overrides = "@rules_cc//cc/toolchains/features:dbg",
    visibility = ["//visibility:public"],
)

cc_feature(
    name = "fastbuild",
    overrides = "@rules_cc//cc/toolchains/features:fastbuild",
    visibility = ["//visibility:public"],
)

cc_feature(
    name = "opt",
    overrides = "@rules_cc//cc/toolchains/features:opt",
    visibility = ["//visibility:public"],
)

config_setting(
    name = "opt_mode",
    values = {"compilation_mode": "opt"},
)

cc_feature(
    name = "dynamic_linking_mode",
    overrides = "@rules_cc//cc/toolchains/features:dynamic_linking_mode",
    target_compatible_with = ["@platforms//os:macos"],
)

cc_feature(
    name = "sysroot_feature",
    args = [":sysroot_args"],
    feature_name = "sysroot",
)

cc_args(
    name = "sysroot_args",
    actions = [
        "@rules_cc//cc/toolchains/actions:compile_actions",
        # TODO: Should all link actions be here?
        "@rules_cc//cc/toolchains/actions:objc_executable",
    ],
    args = [
        "-isysroot",
        "__BAZEL_XCODE_SDKROOT__",
        "-F__BAZEL_XCODE_SDKROOT__/System/Library/Frameworks",
        "-F{PLATFORM_FRAMEWORKS}",  # NOTE: This is lazy so cquery doesn't show the right value
    ],
    toolchains = [":dynamic_toolchain_info"],
)

# TODO: This is overriding a magic name from the default feature set but isn't reading the upstream variable
negatable_feature(
    name = "unfiltered_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-Wno-builtin-macro-redefined",
        "-D__DATE__=\"redacted\"",
        "-D__TIMESTAMP__=\"redacted\"",
        "-D__TIME__=\"redacted\"",
    ],
    overrides = "@rules_cc//cc/toolchains/features/legacy:unfiltered_compile_flags",
)

cc_feature(
    name = "default_compile_flags_feature",
    args = [":default_compile_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:default_compile_flags",
)

cc_args_list(
    name = "default_compile_flags",
    args = [
        ":objcpp_default_flags",
        "//toolchain/sanitizers:no_asan_compile_flags",
        ":always_compile_flags",
        ":fastbuild_compile_flags",
        ":opt_compile_flags",
        ":dbg_compile_flags",
    ],
)

cc_args(
    name = "objcpp_default_flags",
    actions = ["@rules_cc//cc/toolchains/actions:objcpp_compile"],
    args = [
        "-stdlib=libc++",
        "-std=gnu++17",
    ],
)

cc_args(
    name = "always_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-fstack-protector",
        "-fcolor-diagnostics",
        "-Wall",
        "-Wthread-safety",
        "-Wself-assign",
        "-fno-omit-frame-pointer",
    ],
)

cc_args(
    name = "fastbuild_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-O0",
        "-DDEBUG",
    ],
    requires_any_of = [":fastbuild"],
)

cc_args(
    name = "opt_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-g0",
        "-O2",
        "-DNDEBUG",
    ],
    requires_any_of = [":opt"],
)

cc_feature_constraint(
    name = "not_opt_mode",
    none_of = [":opt"],
)

cc_args(
    name = "dbg_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-O0",
        "-DDEBUG",
        "-g",
    ],
    requires_any_of = [":dbg"],
)

negatable_feature(
    name = "ns_block_assertions",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = ["-DNS_BLOCK_ASSERTIONS=1"],
    requires_any_of = [":opt"],
)

negatable_feature(
    name = "debug_prefix_map_pwd_is_dot",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = ["-fdebug-prefix-map=__BAZEL_EXECUTION_ROOT__=."],
)

negatable_feature(
    name = "remap_xcode_path",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-fdebug-prefix-map=__BAZEL_XCODE_DEVELOPER_DIR__=/PLACEHOLDER_DEVELOPER_DIR",
    ],
)

enableable_feature(
    name = "serialized_diagnostics_file",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "--serialize-diagnostics",
        "{serialized_diagnostics_file}",
    ],
    format = {"serialized_diagnostics_file": "@rules_cc//cc/toolchains/variables:serialized_diagnostics_file"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:serialized_diagnostics_file",
)

cc_args(
    name = "clt_env",
    actions = ["@rules_cc//cc/toolchains/actions:all_actions"],
    env = {
        "DEVELOPER_DIR": "/Library/Developer/CommandLineTools",
        "SDKROOT": "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
        "ZERO_AR_DATE": "1",
    },
)

cc_args(
    name = "xcode_env",
    actions = ["@rules_cc//cc/toolchains/actions:all_actions"],
    env = {
        "APPLE_SDK_PLATFORM": "{APPLE_SDK_PLATFORM}",
        "APPLE_SDK_VERSION_OVERRIDE": "{APPLE_SDK_VERSION_OVERRIDE}",
        "XCODE_VERSION_OVERRIDE": "{XCODE_VERSION_OVERRIDE}",
        "ZERO_AR_DATE": "1",
    },
    toolchains = [":dynamic_toolchain_info"],
)

dynamic_toolchain_info(
    name = "dynamic_toolchain_info",
    visibility = ["//:__subpackages__"],
)

xcode_execution_info(
    name = "xcode_execution_info",
    visibility = ["//toolchain:__subpackages__"],
)

negatable_feature(
    name = "default_required_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
        "@rules_cc//cc/toolchains/actions:compile_actions",
    ],
    args = [
        "-no-canonical-prefixes",
    ] + select({
        "//configs:apple": [
            "-target",
            "{TARGET}",
        ],
        "//conditions:default": [],
    }),
    toolchains = select({
        "//configs:apple": [":dynamic_toolchain_info"],
        "//conditions:default": [],
    }),
)

negatable_feature(
    name = "__apply_simulator_compiler_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:objc_compile",
        "@rules_cc//cc/toolchains/actions:objcpp_compile",
    ],
    args = select({
        "//constraints:simulator": [
            "-fexceptions",
            "-fasm-blocks",
            "-fobjc-abi-version=2",
            "-fobjc-legacy-dispatch",
        ],
        "//conditions:default": [],
    }),
)

cc_args(
    name = "default_link_flags_base_args",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = select({
        "//configs:apple": ["-fobjc-link-runtime"],
        "//conditions:default": [
            "-fuse-ld=lld",
            "-Wl,-no-as-needed",
            "-Wl,-z,relro,-z,now",
        ],
    }),
    requires_any_of = [":not_kernel_extension"],
)

negatable_feature(
    name = "default_link_flags",
    custom_args = [":default_link_flags_base_args"],
)

cc_args(
    name = "generate_dsym_compile_flags",
    actions = _LIMITED_COMPILE_ACTIONS + [
        "@rules_cc//cc/toolchains/actions:objc_executable",
    ],
    args = ["-g"],
)

cc_args(
    name = "generate_dsym_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["DSYM_HINT_DSYM_PATH={dsym_path}"],
    format = {"dsym_path": "@rules_cc//cc/toolchains/variables:dsym_path"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:dsym_path",
)

enableable_feature(
    name = "generate_dsym_file",
    custom_args = [
        ":generate_dsym_compile_flags",
        ":generate_dsym_link_flags",
    ],
    overrides = "@rules_cc//cc/toolchains/features/legacy:generate_dsym_file",
)

negatable_feature(
    name = "pch",
    actions = _LIMITED_COMPILE_ACTIONS,
    args = [
        "-include",
        "{pch_file}",
    ],
    format = {"pch_file": "@rules_cc//cc/toolchains/variables:pch_file"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:pch_file",
)

enableable_feature(
    name = "suppress_warnings",
    actions = _LIMITED_COMPILE_ACTIONS,
    args = ["-w"],
)

cc_args(
    name = "treat_warnings_as_errors_compile_args",
    actions = _LIMITED_COMPILE_ACTIONS,
    args = ["-Werror"],
)

cc_args(
    name = "treat_warnings_as_errors_link_args",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = select({
        "//configs:apple": ["-Wl,-fatal_warnings"],
        "//conditions:default": ["-Wl,--fatal-warnings"],
    }),
)

enableable_feature(
    name = "treat_warnings_as_errors",
    custom_args = [
        ":treat_warnings_as_errors_compile_args",
        ":treat_warnings_as_errors_link_args",
    ],
)

# TODO: Remove after https://github.com/bazelbuild/rules_cc/pull/386
enableable_feature(
    name = "external_include_paths",
    custom_args = ["@rules_cc//cc/toolchains/args/external_include_paths"],
)

cc_args(
    name = "generate_linkmap_apple_args",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-Xlinker",
        "-map",
        "-Xlinker",
        "{linkmap_exec_path}",
    ],
    format = {"linkmap_exec_path": "@rules_cc//cc/toolchains/variables:linkmap_exec_path"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:linkmap_exec_path",
)

cc_args(
    name = "generate_linkmap_other_args",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-Xlinker",
        "-map",
        "-Xlinker",
        "{output_execpath}.map",
    ],
    format = {"output_execpath": "@rules_cc//cc/toolchains/variables:output_execpath"},
    requires_none = "@rules_cc//cc/toolchains/variables:linkmap_exec_path",
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_execpath",
)

enableable_feature(
    name = "generate_linkmap",
    custom_args = [
        ":generate_linkmap_apple_args",
        ":generate_linkmap_other_args",
    ],
)

negatable_feature(
    name = "oso_prefix_is_pwd",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-Wl,-oso_prefix,__BAZEL_EXECUTION_ROOT__/"],
)

negatable_feature(
    name = "strip_debug_symbols",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["STRIP_DEBUG_SYMBOLS"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:strip_debug_symbols",
    requires_not_none = "@rules_cc//cc/toolchains/variables:strip_debug_symbols",
)

config_setting(
    name = "no_xcode_version",
    flag_values = {"@bazel_tools//tools/osx:xcode_version_flag_major": "None"},
)

alias(
    name = "apple_env",
    actual = select({
        ":no_xcode_version": ":clt_env",
        "//conditions:default": ":xcode_env",
    }),
)

selects.config_setting_group(
    name = "darwin_x86_64",
    match_all = [
        "@platforms//cpu:x86_64",
        "@platforms//os:macos",
    ],
)

selects.config_setting_group(
    name = "darwin_arm64e",
    match_all = [
        "@platforms//cpu:arm64e",
        "@platforms//os:macos",
    ],
)

selects.config_setting_group(
    name = "kernel_extension_platforms",
    match_any = [
        ":darwin_x86_64",
        # Kernel extensions for Apple Silicon are arm64e.
        ":darwin_arm64e",
        "@platforms//os:ios",
    ],
)

enableable_feature(
    name = "kernel_extension",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = select({
        ":kernel_extension_platforms": [
            "-nostdlib",
            "-Xlinker",
            "-kext",
            "-lcc_kext",
        ],
        "//conditions:default": [],
    }) + select({
        "@platforms//os:macos": [
            "-lkmod",
            "-lkmodc++",
        ],
        "//conditions:default": [],
    }),
)

cc_feature_constraint(
    name = "not_kernel_extension",
    none_of = [":kernel_extension"],
    visibility = ["//toolchain:__subpackages__"],
)

negatable_feature(
    name = "link_libc++",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-lc++"],
    requires_any_of = [":not_kernel_extension"],
)

negatable_feature(
    name = "output_execpath_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-o",
        "{output_execpath}",
        "LINKED_BINARY={output_execpath}",
    ],
    format = {"output_execpath": "@rules_cc//cc/toolchains/variables:output_execpath"},
    overrides = "@rules_cc//cc/toolchains/features/legacy:output_execpath_flags",
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_execpath",
)

negatable_feature(
    name = "linux_output_execpath_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-o",
        "{output_execpath}",
    ],
    format = {"output_execpath": "@rules_cc//cc/toolchains/variables:output_execpath"},
    overrides = "@rules_cc//cc/toolchains/features/legacy:output_execpath_flags",
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_execpath",
)

# We need to pass -object_path_lto in order to get debug symbols when building
# with LTO. In a perfect world, we would only pass it when the thin_lto or
# full_lto features are enabled. However, when these features are enabled,
# bazel will follow the linking steps expected by the traditional llvm tools,
# which doesn't work on Apple platforms. On MacOS, passing -flto (or
# -flto=thin) to the compiler is mostly enough for the linker to do the right
# thing. The only thing left is to tell ld64 to keep the intermediate .o file,
# so dsymutil can find it. We're doing that here by passing -object_path_lto to
# every linking action. If LTO is disabled, it will be a no-op for the linker.
# But if it is enabled, it will allow dsymutil to find the symbols and put it
# in the .dSYM folder. Luckily for us, both ld64 and dsymutil run in the same
# action, so the fact that it's not declared as an output is not a problem.
negatable_feature(
    name = "lto_object_path",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-Xlinker",
        "-object_path_lto",
        "-Xlinker",
        "{output_execpath}.lto.o",
    ],
    format = {"output_execpath": "@rules_cc//cc/toolchains/variables:output_execpath"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_execpath",
)

# As of Xcode 15, linker warnings are emitted if duplicate `-l` options are
# present. Until such linkopts can be deduped by bazel itself, we disable these
# warnings.
negatable_feature(
    name = "no_warn_duplicate_libraries",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-Wl,-no_warn_duplicate_libraries"],
)

negatable_feature(
    name = "reproducible_linker_flag",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-Wl,-reproducible"],
)

negatable_feature(
    name = "no_deduplicate",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = select({
        "//configs:apple": [
            "-Xlinker",
            "-no_deduplicate",
        ],
        "//conditions:default": [],
    }),
    requires_any_of = [":not_opt_mode"],
)

negatable_feature(
    name = "user_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["{user_link_flags}"],
    format = {"user_link_flags": "@rules_cc//cc/toolchains/variables:user_link_flags"},
    iterate_over = "@rules_cc//cc/toolchains/variables:user_link_flags",
    overrides = "@rules_cc//cc/toolchains/features/legacy:user_link_flags",
    requires_not_none = "@rules_cc//cc/toolchains/variables:user_link_flags",
)

negatable_feature(
    name = "headerpad",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = select({
        "//configs:apple": ["-headerpad_max_install_names"],
        "//conditions:default": [],
    }),
)

negatable_feature(
    name = "function_sections",
    actions = [
        "@rules_cc//cc/toolchains/actions:compile_actions",
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = select({
        "//configs:apple": [],
        "//conditions:default": [
            "-fdata-sections",
            "-ffunction-sections",
        ],
    }),
)

enableable_feature(
    name = "dead_strip",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = select({
        "//configs:apple": ["-dead_strip"],
        "//conditions:default": ["-Wl,--gc-sections"],
    }),
)

negatable_feature(
    name = "apply_implicit_frameworks",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = select({
        "@platforms//os:macos": [
            "-framework",
            "Foundation",
        ],
        "@platforms//os:ios": [
            "-framework",
            "Foundation",
            "-framework",
            "UIKit",
        ],
        "@platforms//os:tvos": [
            "-framework",
            "Foundation",
            "-framework",
            "UIKit",
        ],
        "@platforms//os:visionos": [
            "-framework",
            "Foundation",
            "-framework",
            "UIKit",
        ],
        "@platforms//os:watchos": [
            "-framework",
            "Foundation",
            "-framework",
            "UIKit",
        ],
        "//conditions:default": [],
    }),
    requires_any_of = [":not_kernel_extension"],
)

enableable_feature(
    name = "link_cocoa",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = select({
        "@platforms//os:macos": [
            "-framework",
            "Cocoa",
        ],
        "//conditions:default": [],
    }),
)

cc_feature_constraint(
    name = "parse_headers_as_c_enabled",
    all_of = [":parse_headers_as_c"],
    visibility = ["//visibility:public"],
)

cc_feature_constraint(
    name = "not_parse_headers_as_c",
    none_of = [":parse_headers_as_c"],
    visibility = ["//visibility:public"],
)

cc_args(
    name = "_header_parsing_flags_cpp_args",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_header_parsing"],
    args = [
        "-xc++-header",
        "-fsyntax-only",
    ],
    env = {"HEADER_PARSING_OUTPUT": "{output_file}"},
    format = {"output_file": "@rules_cc//cc/toolchains/variables:output_file"},
    requires_any_of = [":not_parse_headers_as_c"],
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_file",
)

cc_args(
    name = "_header_parsing_flags_c_args",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_header_parsing"],
    args = [
        "-xc-header",
        "-fsyntax-only",
    ],
    env = {"HEADER_PARSING_OUTPUT": "{output_file}"},
    format = {"output_file": "@rules_cc//cc/toolchains/variables:output_file"},
    requires_any_of = [":parse_headers_as_c_enabled"],
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_file",
)

negatable_feature(
    name = "__header_parsing_flags",
    custom_args = [
        ":_header_parsing_flags_cpp_args",
        ":_header_parsing_flags_c_args",
    ],
)

cc_artifact_name_pattern(
    name = "dylib_pattern",
    category = "@rules_cc//cc/toolchains/artifacts:dynamic_library",
    extension = ".dylib",
    prefix = "lib",
)

cc_make_variable(
    name = "stack_frame_variable",
    value = "-Wframe-larger-than=100000000 -Wno-vla",
    variable_name = "STACK_FRAME_UNLIMITED",
)

negatable_feature(
    name = "__layering_check_modulemap",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    data = ["//crosstool:generate_layering_check_modulemap"],
    env = {"APPLE_SUPPORT_MODULEMAP": "{modulemap}"},
    format = {"modulemap": "//crosstool:generate_layering_check_modulemap"},
    requires_any_of = ["@rules_cc//cc/toolchains/args/layering_check"],
    visibility = ["//visibility:public"],  # Referenced through the optional enabling of layering_check
)

# TODO: Remove verifying that objc_fully_link_static_library doesn't break
cc_feature(
    name = "__archiver_flags",
    args = [":archiver_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:archiver_flags",
)

cc_args_list(
    name = "archiver_flags",
    args = [
        ":create_static_archive",
        ":output_execpath",
        ":libraries_to_link",
    ],
)

cc_args(
    name = "create_static_archive",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_link_static_library"],
    args = [
        "-D",
        "-no_warning_for_no_symbols",
        "-static",
    ],
)

cc_args(
    name = "output_execpath",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_link_static_library"],
    args = [
        "-o",
        "{output_execpath}",
    ],
    format = {"output_execpath": "@rules_cc//cc/toolchains/variables:output_execpath"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_execpath",
)

cc_args(
    name = "libraries_to_link",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_link_static_library"],
    nested = ["libraries_to_link_expansion"],
    requires_not_none = "@rules_cc//cc/toolchains/variables:libraries_to_link",
)

cc_nested_args(
    name = "libraries_to_link_expansion",
    iterate_over = "@rules_cc//cc/toolchains/variables:libraries_to_link",
    nested = [
        ":link_obj_file",
        ":link_object_file_group",
    ],
)

cc_nested_args(
    name = "link_obj_file",
    args = ["{object_file}"],
    format = {"object_file": "@rules_cc//cc/toolchains/variables:libraries_to_link.name"},
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "object_file",
)

cc_nested_args(
    name = "link_object_file_group",
    args = ["{object_files}"],
    format = {"object_files": "@rules_cc//cc/toolchains/variables:libraries_to_link.object_files"},
    iterate_over = "@rules_cc//cc/toolchains/variables:libraries_to_link.object_files",
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "object_file_group",
)

cc_legacy_tool(
    name = "gcov",
    path = "/usr/bin/gcov",
    tool_name = "gcov",
)

cc_toolchain(
    name = "toolchain",
    module_map = "//crosstool:module.modulemap",
    supports_header_parsing = True,
    sysroot_feature = ":sysroot_feature",
    target = "$(TARGET)",
    tool_map = "//toolchain/tools",
)
