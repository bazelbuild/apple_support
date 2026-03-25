load("@bazel_skylib//lib:selects.bzl", "selects")
load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:args_list.bzl", "cc_args_list")
load("@rules_cc//cc/toolchains:artifacts.bzl", "cc_artifact_name_pattern")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:feature_constraint.bzl", "cc_feature_constraint")
load("@rules_cc//cc/toolchains:make_variable.bzl", "cc_make_variable")
load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")
load(":dynamic_toolchain_info.bzl", "dynamic_toolchain_info", "set_install_name_flag")
load(":features.bzl", "enableable_feature", "negatable_feature")

MARKER_FEATURES = [
    "archive_param_file",
    "compile_all_modules",
    "compiler_param_file",
    "exclude_private_headers_in_module_maps",
    "no_dotd_file",
    "no_legacy_features",
    "only_doth_headers_in_module_maps",
    "parse_headers",
]

ENABLED_MARKERS = [
    "archive_param_file",
]

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
    name = "dbg",
    overrides = "@rules_cc//cc/toolchains/features:dbg",
)

cc_feature(
    name = "fastbuild",
    overrides = "@rules_cc//cc/toolchains/features:fastbuild",
)

cc_feature(
    name = "opt",
    overrides = "@rules_cc//cc/toolchains/features:opt",
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
    args = ["-g"],
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
        "-target",
        "{TARGET}",
    ],
    toolchains = [":dynamic_toolchain_info"],
)

negatable_feature(
    name = "__apply_simulator_compiler_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:objc_compile",
        "@rules_cc//cc/toolchains/actions:objcpp_compile",
    ],
    args = select({
        "@build_bazel_apple_support//constraints:simulator": [
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
    args = ["-fobjc-link-runtime"],
)

cc_args(
    name = "default_link_flags_opt_args",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-dead_strip"],
    requires_any_of = [":opt"],
)

negatable_feature(
    name = "default_link_flags",
    custom_args = [
        ":default_link_flags_base_args",
        ":default_link_flags_opt_args",
    ],
)

cc_args(
    name = "generate_dsym_compile_flags",
    actions = _LIMITED_COMPILE_ACTIONS + [
        "@rules_cc//cc/toolchains/actions:objc_executable",
    ],
    args = ["-g"],
)

enableable_feature(
    name = "generate_dsym_file",
    custom_args = [
        ":generate_dsym_compile_flags",
        ":generate_dsym_link_flags",
    ],
    overrides = "@rules_cc//cc/toolchains/features/legacy:generate_dsym_file",
)

cc_args(
    name = "generate_dsym_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["DSYM_HINT_DSYM_PATH={dsym_path}"],
    format = {"dsym_path": "@rules_cc//cc/toolchains/variables:dsym_path"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:dsym_path",
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
    args = ["-Wl,-fatal_warnings"],
)

enableable_feature(
    name = "treat_warnings_as_errors",
    custom_args = [
        ":treat_warnings_as_errors_compile_args",
        ":treat_warnings_as_errors_link_args",
    ],
)

# TODO: Remove after https://github.com/bazelbuild/rules_cc/pull/386
cc_feature(
    name = "external_include_paths",
    feature_name = "external_include_paths",
)

cc_feature(
    name = "external_include_paths_wrapper",
    args = ["@rules_cc//cc/toolchains/args/external_include_paths"],
    feature_name = "__external_include_paths_wrapper",
    requires_any_of = [":external_include_paths"],
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
    ],
)

enableable_feature(
    name = "kernel_extension",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = select({
        ":kernel_extension_platforms": [
            "-nostdlib",
            "-lkmod",
            "-lkmodc++",
            "-lcc_kext",
            "-Xlinker",
            "-kext",
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

# We need to pass -object_path_lto in order to get debug symbols when building with LTO.
# In a perfect world, we would only pass it when the thin_lto or full_lto features are enabled.
# However, when these features are enabled, bazel will follow the linking steps expected by
# the traditional llvm tools, which doesn't work on Apple platforms.
# On MacOS, passing -flto (or -flto=thin) to the compiler is mostly enough for the linker to
# do the right thing. The only thing left is to tell ld64 to keep the intermediate .o file,
# so dsymutil can find it.
# We're doing that here by passing -object_path_lto to every linking action. If LTO is disabled,
# it will be a no-op for the linker. But if it is enabled, it will allow dsymutil to find the
# symbols and put it in the .dSYM folder. Luckily for us, both ld64 and dsymutil run in the same
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

negatable_feature(
    name = "no_warn_duplicate_libraries",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-Wl,-no_warn_duplicate_libraries"],
)

negatable_feature(
    name = "no_deduplicate",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-Xlinker",
        "-no_deduplicate",
    ],
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
    args = ["-headerpad_max_install_names"],
)

enableable_feature(
    name = "dead_strip",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-dead_strip"],
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

negatable_feature(
    name = "__header_parsing_flags",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_header_parsing"],
    args = [
        # Note: This treats all headers as C++ headers, which may lead to
        # parsing failures for C headers that are not valid C++.
        # For such headers, use features = ["-parse_headers"] to selectively
        # disable parsing.
        "-xc++-header",
        "-fsyntax-only",
    ],
    env = {"HEADER_PARSING_OUTPUT": "{output_file}"},
    format = {"output_file": "@rules_cc//cc/toolchains/variables:output_file"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_file",
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

# TODO: Remove when we drop bazel 8.x support (maybe earlier)
set_install_name_flag(
    name = "set_install_name_flag",
)

config_setting(
    name = "should_set_install_name",
    flag_values = {":set_install_name_flag": "True"},
)

# TODO: Use upstream's after https://github.com/bazelbuild/rules_cc/pull/651
negatable_feature(
    name = "set_install_name",
    actions = ["@rules_cc//cc/toolchains/actions:dynamic_library_link_actions"],
    args = [
        "-Xlinker",
        "-install_name",
        "-Xlinker",
        "@rpath/{runtime_solib_name}",
    ],
    format = {"runtime_solib_name": "@rules_cc//cc/toolchains/variables:runtime_solib_name"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:runtime_solib_name",
    target_compatible_with = ["@rules_cc//cc/toolchains/platforms:apple"],
)

# TODO: Remove https://github.com/bazelbuild/rules_cc/pull/653
negatable_feature(
    name = "user_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = ["{user_compile_flags}"],
    format = {"user_compile_flags": "@rules_cc//cc/toolchains/variables:user_compile_flags"},
    iterate_over = "@rules_cc//cc/toolchains/variables:user_compile_flags",
    overrides = "@rules_cc//cc/toolchains/features/legacy:user_compile_flags",
    requires_not_none = "@rules_cc//cc/toolchains/variables:user_compile_flags",
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

cc_toolchain(
    name = "toolchain",
    args = [
        "@apple_support_toolchain_env//:include_directories_from_xcode",
    ] + select({
        ":no_xcode_version": [":clt_env"],
        "//conditions:default": [":xcode_env"],
    }),
    artifact_name_patterns = [":dylib_pattern"],
    compiler = "clang",
    # TODO: Use experimental_replace_legacy_action_config_features as long as ordering isn't an issue
    enabled_features = ENABLED_MARKERS + [
        # NOTE: ORDER MATTERS
        "@rules_cc//cc/toolchains/args/layering_check:module_maps",  # NOTE: This is a marker feature
        "@rules_cc//cc/toolchains/args/strip_flags:feature",
        "//toolchain/objc:__objc_executable_feature",
        "//toolchain/objc:__objc_fully_link_feature",
        ":__header_parsing_flags",  # NOTE: Must come before input files
        ":link_libc++",
        ":default_compile_flags_feature",
        ":ns_block_assertions",
        ":debug_prefix_map_pwd_is_dot",
        ":remap_xcode_path",
        ":generate_dsym_file_wrapper",
        ":generate_linkmap_wrapper",
        ":oso_prefix_is_pwd",
        ":strip_debug_symbols",
        "@rules_cc//cc/toolchains/args/shared_flag:feature",
        ":kernel_extension_wrapper",
        ":output_execpath_flags",
        "@rules_cc//cc/toolchains/args/runtime_library_search_directories:feature",
        "@rules_cc//cc/toolchains/args/library_search_directories:feature",
        "@rules_cc//cc/toolchains/args/libraries_to_link:feature",
        "//toolchain/objc:objc_link_flag",
        ":pch",
        "//toolchain/objc:__apple_default_warnings",
        "@rules_cc//cc/toolchains/args/archiver_flags:feature",
        "@rules_cc//cc/toolchains/args/include_flags:feature",
        "@rules_cc//cc/toolchains/args/dependency_file:feature",
        ":serialized_diagnostics_file_wrapper",
        "@rules_cc//cc/toolchains/args/pic_flags:feature",
        "@rules_cc//cc/toolchains/args/preprocessor_defines:feature",
        "//toolchain/pgo:fdo_instrument_wrapper",
        "//toolchain/pgo:fdo_optimize_wrapper",
        "//toolchain/pgo:autofdo_wrapper",
        ":lto_object_path",
        "//toolchain/coverage:llvm_coverage_map_format_wrapper",
        "//toolchain/coverage:gcc_coverage_map_format_wrapper",
        "//toolchain/coverage:coverage_prefix_map",
        "//toolchain/coverage:_coverage_prefix_map_absolute_sources_non_hermetic_wrapper",
        "//toolchain/objc:__apple_default_compiler_flags",
        ":sysroot_feature",
        ":headerpad",
        "@rules_cc//cc/toolchains/args/objc_arc_flags:feature",
        ":user_link_flags",  # TODO: Switch to upstream feature
        "@apple_support_toolchain_env//:linkopts_from_env",  # TODO: Join with the copts below
        ":default_required_flags",
        ":__apply_simulator_compiler_flags",
        "@apple_support_toolchain_env//:copts_from_env",
        ":default_link_flags",
        ":no_deduplicate",
        ":dead_strip_wrapper",
        ":apply_implicit_frameworks",
        ":link_cocoa_wrapper",
        ":user_compile_flags",  # TODO: Switch to compile_flags:feature if ordering isn't an issue
        ":unfiltered_compile_flags",
        "@rules_cc//cc/toolchains/args/compiler_input_flags:feature",
        "@rules_cc//cc/toolchains/args/compiler_output_flags:feature",
        "@rules_cc//cc/toolchains/args/linker_param_file:feature",
    ] + select({
        ":should_set_install_name": [":set_install_name"],
        "//conditions:default": [],
    }) + [
        "//toolchain/sanitizers:asan_wrapper",
        "//toolchain/sanitizers:tsan_wrapper",
        "//toolchain/sanitizers:ubsan_wrapper",
        "//toolchain/sanitizers:default_sanitizer_flags",
        ":suppress_warnings_wrapper",
        ":treat_warnings_as_errors_wrapper",
        ":no_warn_duplicate_libraries",
        ":external_include_paths_wrapper",
        "@apple_support_toolchain_env//:off_by_default_layering_check_enabled_features",
    ],
    known_features = MARKER_FEATURES + [
        ":opt",
        ":dbg",
        ":fastbuild",
        "//toolchain/coverage",
        ":kernel_extension",
        ":serialized_diagnostics_file",
        "//toolchain/coverage:llvm_coverage_map_format",
        "//toolchain/coverage:gcc_coverage_map_format",
        "//toolchain/coverage:_coverage_prefix_map_absolute_sources_non_hermetic",
        "//toolchain/sanitizers:asan",
        "//toolchain/sanitizers:tsan",
        "//toolchain/sanitizers:ubsan",
        ":generate_dsym_file",
        ":generate_linkmap",
        ":link_cocoa",
        ":dead_strip",
        ":suppress_warnings",
        ":treat_warnings_as_errors",
        ":external_include_paths",
        "//toolchain/pgo:fdo_instrument",
        "//toolchain/pgo:autofdo",
        "//toolchain/pgo:fdo_optimize",
        "@apple_support_toolchain_env//:off_by_default_layering_check_known_features",
        "@rules_cc//cc/toolchains/args/layering_check:use_module_maps",  # TODO: https://github.com/bazelbuild/rules_cc/pull/657
    ] + select({
        "@platforms//os:macos": [
            ":dynamic_linking_mode",
        ],
        "//conditions:default": [],
    }),
    make_variables = [":stack_frame_variable"],
    module_map = "//crosstool:module.modulemap",
    supports_header_parsing = True,
    supports_param_files = True,
    target_system_name = "$(TARGET)",
    tool_map = "//toolchain/tools",
    toolchains = [":dynamic_toolchain_info"],
    visibility = ["//:__subpackages__"],
)

# TODO: Remove https://github.com/bazelbuild/rules_cc/pull/652
alias(
    name = "toolchain_config",
    testonly = True,
    actual = ":_toolchain_config",
    visibility = ["//test:__subpackages__"],
)
