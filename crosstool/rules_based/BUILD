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
    env = {
        # FIXME: apple env
        "DEVELOPER_DIR": "/Library/Developer/CommandLineTools",
        "SDKROOT": "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
        "ZERO_AR_DATE": "1",
    },

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
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
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
        "@rules_cc//cc/toolchains/features/legacy:autofdo",
        "@rules_cc//cc/toolchains/features/legacy:fdo_optimize",
        "@rules_cc//cc/toolchains/features/legacy:fdo_instrument",
    ],
)

cc_mutually_exclusive_category(
    name = "profile",
)

cc_toolchain(
    name = "foo",  # name = "cc-compiler-" + cpu,
    compiler = "clang",
    # TODO: Use experimental_replace_legacy_action_config_features as long as ordering isn't an issue
    enabled_features = ENABLED_MARKERS + [
        # NOTE: ORDER MATTERS
        "@rules_cc//cc/toolchains/args/strip_flags:feature",
        "@rules_cc//cc/toolchains/args/preprocessor_defines:feature",
        ":pch",
        ":default_compile_flags_feature",
        ":ns_block_assertions",
        ":generate_dsym_file_wrapper",
        ":debug_prefix_map_pwd_is_dot",
        ":remap_xcode_path",
        "@rules_cc//cc/toolchains/args/dependency_file:feature",
        ":serialized_diagnostics_file_wrapper",
        ":lipo_wrapper",
        ":llvm_coverage_map_format_wrapper",
        ":gcc_coverage_map_format_wrapper",
        ":coverage_prefix_map",
        ":_coverage_prefix_map_absolute_sources_non_hermetic_wrapper",
        ":sysroot_feature",
        "@rules_cc//cc/toolchains/args/objc_arc_flags:feature",
        ":default_required_flags",
        "@apple_support_toolchain_env//:copts_from_env",
        "@rules_cc//cc/toolchains/args/compile_flags:user_compile_flags_feature",  # TODO: Switch to compile_flags:feature if ordering isn't an issue
        ":unfiltered_compile_flags_feature",
        "@rules_cc//cc/toolchains/args/compiler_input_flags:feature",
        "@rules_cc//cc/toolchains/args/compiler_output_flags:feature",
        ":asan_wrapper",
        ":tsan_wrapper",
        ":ubsan_wrapper",
        ":default_sanitizer_flags",
        ":suppress_warnings_wrapper",
        ":treat_warnings_as_errors_wrapper",
        ":external_include_paths_wrapper",
    ],
    # args = toolhain_args,
    known_features = MARKER_FEATURES + [
        "@rules_cc//cc/toolchains/features:opt",
        "@rules_cc//cc/toolchains/features:dbg",
        "@rules_cc//cc/toolchains/features:fastbuild",
        "@rules_cc//cc/toolchains/features/legacy:coverage",
        "@rules_cc//cc/toolchains/features/legacy:autofdo",
        "@rules_cc//cc/toolchains/features/legacy:fdo_optimize",
        "@rules_cc//cc/toolchains/features/legacy:fdo_instrument",
        ":serialized_diagnostics_file",
        ":lipo",
        ":llvm_coverage_map_format",
        ":gcc_coverage_map_format",
        ":_coverage_prefix_map_absolute_sources_non_hermetic",
        ":asan",
        ":tsan",
        ":ubsan",
        ":generate_dsym_file",
        ":suppress_warnings",
        ":treat_warnings_as_errors",
        ":external_include_paths",
    ],
    supports_header_parsing = True,
    supports_param_files = True,
    tool_map = "//crosstool/rules_based/tools",
)
