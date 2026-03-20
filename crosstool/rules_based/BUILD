load("@build_bazel_apple_support//configs:platforms.bzl", "APPLE_PLATFORMS_CONSTRAINTS")
load("@rules_cc//cc/toolchains:actions.bzl", "cc_action_type_set")
load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:args_list.bzl", "cc_args_list")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:feature_constraint.bzl", "cc_feature_constraint")
load("@rules_cc//cc/toolchains:feature_set.bzl", "cc_feature_set")
load("@rules_cc//cc/toolchains:mutually_exclusive_category.bzl", "cc_mutually_exclusive_category")
load("@rules_cc//cc/toolchains:nested_args.bzl", "cc_nested_args")
load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")
load(":features.bzl", "enableable_feature", "negatable_feature")

_OSX_DEVELOPER_PLATFORM_CPUS = [
    "arm64",
    "x86_64",
]

MARKER_FEATURES = [
    "no_legacy_features",
    # "asan",
    # "ubsan",
    # "tsan",
    # "serialized_diagnostics_file",
    # "archive_param_file",
    # "compile_all_modules",
    # "exclude_private_headers_in_module_maps",
    # "gcc_quoting_for_param_files",
    # "modular_code",  # Differentiate between third and first party code
    # "module_maps",
    # "only_doth_headers_in_module_maps",
    # "supports_start_end_lib",
    # "sysroot",  # Stop duplicate sysroot confusion until legacy features are disabled
]

ENABLED_MARKERS = [
    "no_legacy_features",
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
    name = "sysroot_feature",
    args = [":sysroot_args"],
    feature_name = "sysroot",
)

cc_args(
    name = "sysroot_args",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-isysroot",
        "__BAZEL_XCODE_SDKROOT__",
        "-F__BAZEL_XCODE_SDKROOT__/System/Library/Frameworks",
        # "-F" + cpu_info.platform_frameworks_dir,
        "-F__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/MacOSX.platform/Developer/Library/Frameworks",  # FIXME: abstract per platform
    ],
)

cc_feature(
    name = "unfiltered_compile_flags_feature",
    args = [":unfiltered_compile_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:unfiltered_compile_flags",
)

# TODO: This is overriding a magic name from the default feature set but isn't reading the upstream variable
cc_args(
    name = "unfiltered_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-Wno-builtin-macro-redefined",
        "-D__DATE__=\"redacted\"",
        "-D__TIMESTAMP__=\"redacted\"",
        "-D__TIME__=\"redacted\"",
    ],
)

cc_feature(
    name = "default_compile_flags_feature",
    args = [":default_compile_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:default_compile_flags",
)

# cc_feature(
#     name = "asan_feature",
#     feature_name = "asan",
# )

cc_args_list(
    name = "default_compile_flags",
    args = [
        ":no_asan_compile_flags",
        ":always_compile_flags",
        ":fastbuild_compile_flags",
        ":opt_compile_flags",
        ":dbg_compile_flags",
    ],

    # actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
)

cc_feature_constraint(
    name = "not_asan",
    none_of = [
        ":asan",
    ],
)

cc_args(
    name = "no_asan_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-D_FORTIFY_SOURCE=1",
    ],
    requires_any_of = [
        ":not_asan",
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
    requires_any_of = [
        "@rules_cc//cc/toolchains/features:fastbuild",
    ],
)

cc_args(
    name = "opt_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-g0",
        "-O2",
        "-DNDEBUG",
    ],
    requires_any_of = [
        "@rules_cc//cc/toolchains/features:opt",
    ],
)

cc_feature_constraint(
    name = "not_opt_mode",
    none_of = [
        "@rules_cc//cc/toolchains/features:opt",
    ],
)

cc_args(
    name = "dbg_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-g",
    ],
    requires_any_of = [
        "@rules_cc//cc/toolchains/features:dbg",
    ],
)

negatable_feature(
    name = "ns_block_assertions",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-DNS_BLOCK_ASSERTIONS=1",
    ],
    requires_any_of = [
        "@rules_cc//cc/toolchains/features:opt",
    ],
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

# cc_feature(
#     name = "serialized_diagnostics_file_wrapper",
#     args = [":serialized_diagnostics_file_args"],
#     feature_name = "__serialized_diagnostics_file_wrapper",
#     requires_any_of = [":serialized_diagnostics_file"],
# )

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

negatable_feature(
    name = "default_env",
    actions = ["@rules_cc//cc/toolchains/actions:all_actions"],
    env = {
        # FIXME: apple env
        "DEVELOPER_DIR": "/Library/Developer/CommandLineTools",
        "SDKROOT": "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
        "ZERO_AR_DATE": "1",
    },
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
        "arm64-apple-macosx26.2",  # FIXME: abstract
    ],

    # if xcode_config.xcode_version():
    #     apple_env = {
    #         "XCODE_VERSION_OVERRIDE": str(xcode_config.xcode_version()),
    #         # TODO: Remove once we drop bazel 7.x support
    #         "APPLE_SDK_VERSION_OVERRIDE": str(sdk_version),
    #         "APPLE_SDK_PLATFORM": _sdk_name(platform_type, is_simulator),
    #         "ZERO_AR_DATE": "1",
    #     }
    # else:
    #     apple_env = {
    #         "DEVELOPER_DIR": "/Library/Developer/CommandLineTools",
    #         "SDKROOT": "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
    #         "ZERO_AR_DATE": "1",
    #     }
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
    requires_any_of = ["@rules_cc//cc/toolchains/features:opt"],
)

negatable_feature(
    name = "default_link_flags",
    custom_args = [
        ":default_link_flags_base_args",
        ":default_link_flags_opt_args",
    ],
)

# cc_feature(
#     name = "generate_dsym_file_wrapper",
#     args = [
#         ":generate_dsym_compile_flags",
#         ":generate_dsym_link_flags",
#     ],
#     feature_name = "__generate_dsym_file_wrapper",
#     requires_any_of = ["@rules_cc//cc/toolchains/features/legacy:generate_dsym_file"],
# )

cc_args(
    name = "generate_dsym_compile_flags",
    actions = _LIMITED_COMPILE_ACTIONS,  # ACTION_NAMES.objc_executable, # FIXME: intentionally leaving this one out because it's nothing?
    args = ["-g"],
    # requires_not_none = "@rules_cc//cc/toolchains/variables:dsym_path",
)

enableable_feature(
    name = "generate_dsym_file",
    custom_args = [
        ":generate_dsym_compile_flags",
        ":generate_dsym_link_flags",
    ],
    # compile_actions = [
    #     "@rules_cc//cc/toolchains/actions:c_compile",
    #     "@rules_cc//cc/toolchains/actions:cpp_compile",
    #     "@rules_cc//cc/toolchains/actions:objc_compile",
    #     "@rules_cc//cc/toolchains/actions:objcpp_compile",
    #     # ACTION_NAMES.objc_executable, # FIXME: intentionally leaving this one out because it's nothing?
    # ],
    # compile_args = ["-g"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:generate_dsym_file",
    # requires_not_none = "@rules_cc//cc/toolchains/variables:dsym_path",
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
    name = "asan_compile_flags",
    actions = _LIMITED_COMPILE_ACTIONS,
    args = [
        "-fsanitize=address",
    ],
)

cc_args(
    name = "asan_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-fsanitize=address",
    ],
)

enableable_feature(
    name = "asan",
    custom_args = [
        ":asan_compile_flags",
        ":asan_link_flags",
    ],
)

cc_args(
    name = "tsan_compile_flags",
    actions = _LIMITED_COMPILE_ACTIONS,
    args = [
        "-fsanitize=thread",
    ],
)

cc_args(
    name = "tsan_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-fsanitize=thread",
    ],
)

cc_args(
    name = "gcc_coverage_map_format_compile_args",
    actions = [
        # TODO: Should all compile actions be here?
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
        "@rules_cc//cc/toolchains/actions:cpp_module_compile",
        "@rules_cc//cc/toolchains/actions:objc_compile",
        "@rules_cc//cc/toolchains/actions:objcpp_compile",
        "@rules_cc//cc/toolchains/actions:preprocess_assemble",
    ],
    args = [
        "-fprofile-arcs",
        "-ftest-coverage",
        "-g",
    ],
)

cc_args(
    name = "gcc_coverage_map_format_link_args",
    actions = [
        "@rules_cc//cc/toolchains/actions:cpp_link_executable",
        "@rules_cc//cc/toolchains/actions:cpp_link_dynamic_library",
    ],
    args = ["--coverage"],
)

enableable_feature(
    name = "gcc_coverage_map_format",
    custom_args = [
        ":gcc_coverage_map_format_compile_args",
        ":gcc_coverage_map_format_link_args",
    ],
    overrides = "@rules_cc//cc/toolchains/features/legacy:gcc_coverage_map_format",
    requires_any_of = ["@rules_cc//cc/toolchains/features/legacy:coverage"],
)

cc_args(
    name = "llvm_coverage_map_format_compile_args",
    actions = [
        # TODO: Should all compile actions be here?
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
        "@rules_cc//cc/toolchains/actions:cpp_module_compile",
        "@rules_cc//cc/toolchains/actions:objc_compile",
        "@rules_cc//cc/toolchains/actions:objcpp_compile",
        "@rules_cc//cc/toolchains/actions:preprocess_assemble",
    ],
    args = [
        "-fprofile-instr-generate",
        "-fcoverage-mapping",
        "-g",
    ],
)

cc_args(
    name = "llvm_coverage_map_format_link_args",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["-fprofile-instr-generate"],
)

enableable_feature(
    name = "llvm_coverage_map_format",
    custom_args = [
        ":llvm_coverage_map_format_compile_args",
        ":llvm_coverage_map_format_link_args",
    ],
    overrides = "@rules_cc//cc/toolchains/features/legacy:llvm_coverage_map_format",
    requires_any_of = ["@rules_cc//cc/toolchains/features/legacy:coverage"],
)

negatable_feature(
    name = "coverage_prefix_map",
    actions = [
        # TODO: Should all compile actions be here?
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
        "@rules_cc//cc/toolchains/actions:cpp_module_compile",
        "@rules_cc//cc/toolchains/actions:objc_compile",
        "@rules_cc//cc/toolchains/actions:objcpp_compile",
        "@rules_cc//cc/toolchains/actions:preprocess_assemble",
    ],
    args = ["-fcoverage-prefix-map=__BAZEL_EXECUTION_ROOT__=."],
    requires_any_of = ["@rules_cc//cc/toolchains/features/legacy:coverage"],
)

enableable_feature(
    name = "_coverage_prefix_map_absolute_sources_non_hermetic",
    actions = [
        # TODO: Should all compile actions be here?
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
        "@rules_cc//cc/toolchains/actions:cpp_module_compile",
        "@rules_cc//cc/toolchains/actions:objc_compile",
        "@rules_cc//cc/toolchains/actions:objcpp_compile",
        "@rules_cc//cc/toolchains/actions:preprocess_assemble",
    ],
    args = ["-fcoverage-prefix-map=__BAZEL_EXECUTION_ROOT__=__BAZEL_EXECUTION_ROOT_CANONICAL__"],
    env = {"COVERAGE_PREFIX_MAP_USE_ABSOLUTE_CWD_PATH": "1"},
    requires_any_of = ["@rules_cc//cc/toolchains/features/legacy:coverage"],
)

enableable_feature(
    name = "tsan",
    custom_args = [
        ":tsan_compile_flags",
        ":tsan_link_flags",
    ],
)

cc_args(
    name = "ubsan_compile_flags",
    actions = _LIMITED_COMPILE_ACTIONS,
    args = [
        "-fsanitize=undefined",
    ],
)

cc_args(
    name = "ubsan_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-fsanitize=undefined",
    ],
)

enableable_feature(
    name = "ubsan",
    custom_args = [
        ":ubsan_compile_flags",
        ":ubsan_link_flags",
    ],
)

cc_feature(
    name = "default_sanitizer_flags",
    args = [":default_sanitizer_flags_args"],
    feature_name = "default_sanitizer_flags",
    requires_any_of = [
        ":asan",
        ":ubsan",
        ":tsan",
    ],
)

cc_args(
    name = "default_sanitizer_flags_args",
    actions = _LIMITED_COMPILE_ACTIONS,
    args = [
        "-gline-tables-only",
        "-fno-omit-frame-pointer",
        "-fno-sanitize-recover=all",
    ],
)

enableable_feature(
    name = "lipo",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
    ],
    args = ["-fripa"],
    requires_any_of = [
        "//crosstool/rules_based/pgo:autofdo",
        "//crosstool/rules_based/pgo:fdo_instrument",
        "//crosstool/rules_based/pgo:fdo_optimize",
    ],
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

# cc_args(
#     name = "generate_linkmap_args",
#     actions = [":all_dynamic_link_actions"],
#     args = ["-Xlinker", "-map", "-Xlinker", "{output_execpath}.map"],
#     format = {"output_execpath": "@rules_cc//cc/toolchains/variables:output_execpath"},
#     requires_not_none = "@rules_cc//cc/toolchains/variables:output_execpath",
# )

# cc_feature(
#     name = "generate_linkmap",
#     feature_name = "generate_linkmap",
#     args = [":generate_linkmap_args"],
# )

enableable_feature(
    name = "kernel_extension",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = [
        "-nostdlib",
        "-lkmod",
        "-lkmodc++",
        "-lcc_kext",
        "-Xlinker",
        "-kext",
    ],
)

cc_feature_constraint(
    name = "not_kernel_extension",
    none_of = [":kernel_extension"],
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
    name = "no_warn_duplicate_libraries",  # FIXME: enable based on availablity
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-Wl,-no_warn_duplicate_libraries",
    ],
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
        "//conditions:default": [],
    }),
    requires_any_of = [":not_kernel_extension"],
)

cc_toolchain(
    name = "foo",  # name = "cc-compiler-" + cpu,
    compiler = "clang",
    # TODO: Use experimental_replace_legacy_action_config_features as long as ordering isn't an issue
    enabled_features = ENABLED_MARKERS + [
        # NOTE: ORDER MATTERS
        ":link_libc++",
        "@rules_cc//cc/toolchains/args/strip_flags:feature",
        ":default_compile_flags_feature",
        ":ns_block_assertions",
        ":debug_prefix_map_pwd_is_dot",
        ":remap_xcode_path",
        ":generate_dsym_file_wrapper",
        ":generate_linkmap_wrapper",
        ":oso_prefix_is_pwd",
        ":strip_debug_symbols",
        ":kernel_extension_wrapper",
        ":output_execpath_flags",
        "@rules_cc//cc/toolchains/args/runtime_library_search_directories:feature",
        "@rules_cc//cc/toolchains/args/library_search_directories:feature",
        "@rules_cc//cc/toolchains/args/libraries_to_link:feature",
        ":pch",
        "@rules_cc//cc/toolchains/args/archiver_flags:feature",
        "@rules_cc//cc/toolchains/args/include_flags:feature",
        "@rules_cc//cc/toolchains/args/dependency_file:feature",
        ":serialized_diagnostics_file_wrapper",
        "@rules_cc//cc/toolchains/args/pic_flags:feature",
        "@rules_cc//cc/toolchains/args/preprocessor_defines:feature",
        "//crosstool/rules_based/pgo:fdo_instrument_wrapper",
        "//crosstool/rules_based/pgo:fdo_optimize_wrapper",
        "//crosstool/rules_based/pgo:autofdo_wrapper",
        ":lipo_wrapper",
        ":lto_object_path",
        ":llvm_coverage_map_format_wrapper",
        ":gcc_coverage_map_format_wrapper",
        ":coverage_prefix_map",
        ":_coverage_prefix_map_absolute_sources_non_hermetic_wrapper",
        ":sysroot_feature",
        ":headerpad",
        "@rules_cc//cc/toolchains/args/objc_arc_flags:feature",
        ":user_link_flags",  # TODO: Switch to upstream feature
        "@apple_support_toolchain_env//:copts_from_env",
        ":default_required_flags",
        ":default_env",
        ":default_link_flags",
        ":no_deduplicate",
        ":dead_strip_wrapper",
        ":apply_implicit_frameworks",
        "@rules_cc//cc/toolchains/args/compile_flags:user_compile_flags_feature",  # TODO: Switch to compile_flags:feature if ordering isn't an issue
        ":unfiltered_compile_flags_feature",
        "@rules_cc//cc/toolchains/args/compiler_input_flags:feature",
        "@rules_cc//cc/toolchains/args/compiler_output_flags:feature",
        "@rules_cc//cc/toolchains/args/linker_param_file:feature",
        ":asan_wrapper",
        ":tsan_wrapper",
        ":ubsan_wrapper",
        ":default_sanitizer_flags",
        ":suppress_warnings_wrapper",
        ":treat_warnings_as_errors_wrapper",
        ":external_include_paths_wrapper",
        ":no_warn_duplicate_libraries",
    ],
    # args = toolhain_args,
    known_features = MARKER_FEATURES + [
        "@rules_cc//cc/toolchains/features:opt",
        "@rules_cc//cc/toolchains/features:dbg",
        "@rules_cc//cc/toolchains/features:fastbuild",
        "@rules_cc//cc/toolchains/features/legacy:coverage",
        "@rules_cc//cc/toolchains/features/legacy:fdo_optimize",
        "@rules_cc//cc/toolchains/features/legacy:fdo_instrument",
        ":kernel_extension",
        ":serialized_diagnostics_file",
        ":lipo",
        ":llvm_coverage_map_format",
        ":gcc_coverage_map_format",
        ":_coverage_prefix_map_absolute_sources_non_hermetic",
        ":asan",
        ":tsan",
        ":ubsan",
        ":generate_dsym_file",
        ":generate_linkmap",
        ":dead_strip",
        ":suppress_warnings",
        ":treat_warnings_as_errors",
        ":external_include_paths",
        "//crosstool/rules_based/pgo:fdo_instrument",
        "//crosstool/rules_based/pgo:autofdo",
        "//crosstool/rules_based/pgo:fdo_optimize",
    ],
    supports_header_parsing = True,
    supports_param_files = True,
    tool_map = "//crosstool/rules_based/tools",
)

[
    toolchain(
        name = "cc-toolchain-" + arch + "-" + cpu,
        exec_compatible_with = [
            # These only execute on macOS.
            "@platforms//os:macos",
            "@platforms//cpu:" + cpu,
        ],
        target_compatible_with = APPLE_PLATFORMS_CONSTRAINTS[arch],
        toolchain = ":foo",
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
        visibility = ["//visibility:public"],
    )
    for arch in APPLE_PLATFORMS_CONSTRAINTS.keys()
    for cpu in _OSX_DEVELOPER_PLATFORM_CPUS
]
