load("@bazel_skylib//lib:selects.bzl", "selects")
load("@build_bazel_apple_support//configs:platforms.bzl", "APPLE_PLATFORMS_CONSTRAINTS")
load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:args_list.bzl", "cc_args_list")
load("@rules_cc//cc/toolchains:artifacts.bzl", "cc_artifact_name_pattern")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:feature_constraint.bzl", "cc_feature_constraint")
load("@rules_cc//cc/toolchains:make_variable.bzl", "cc_make_variable")
load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")
load(":features.bzl", "enableable_feature", "negatable_feature")
load(":foo.bzl", "foo")

_OSX_DEVELOPER_PLATFORM_CPUS = [
    "arm64",
    "x86_64",
]

# feature(name = "module_maps", enabled = True), # FIXME: enable with layering_check stuff instead
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
    name = "coverage",
    overrides = "@rules_cc//cc/toolchains/features/legacy:coverage",
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
        "-F{PLATFORM_FRAMEWORKS}",  # FIXME: verify working
    ],
    toolchains = [":target_thing"],
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
        ":objcpp_default_flags",
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
    name = "objcpp_default_flags",
    actions = ["@rules_cc//cc/toolchains/actions:objcpp_compile"],
    args = [
        "-stdlib=libc++",
        "-std=gnu++17",
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
    name = "__clt_env",
    actions = ["@rules_cc//cc/toolchains/actions:all_actions"],
    env = {
        "DEVELOPER_DIR": "/Library/Developer/CommandLineTools",
        "SDKROOT": "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
        "ZERO_AR_DATE": "1",
    },
)

negatable_feature(
    name = "__xcode_env",
    actions = ["@rules_cc//cc/toolchains/actions:all_actions"],
    env = {
        "XCODE_VERSION_OVERRIDE": "{XCODE_VERSION_OVERRIDE}",
        "APPLE_SDK_VERSION_OVERRIDE": "{APPLE_SDK_VERSION_OVERRIDE}",
        "APPLE_SDK_PLATFORM": "{APPLE_SDK_PLATFORM}",
        "ZERO_AR_DATE": "1",
    },
    toolchains = [":target_thing"],
)

foo(
    name = "target_thing",
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
    toolchains = [":target_thing"],
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
    requires_any_of = [":coverage"],
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
    requires_any_of = [":coverage"],
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
    requires_any_of = [":coverage"],
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
    requires_any_of = [":coverage"],
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
        ":darwin_arm64e",
    ],
)

enableable_feature(
    name = "kernel_extension",
    actions = ["@rules_cc//cc/toolchains/actions:objc_executable"],
    args = select({
        # Kernel extensions for Apple Silicon are arm64e.
        ":kernel_extension_platforms": [
            # ("//platforms:darwin_x86_64", "//platforms:darwin_arm64e"): [
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
        "@platforms//os:tvos": ["-DOS_TVOS"],  # NOTE: This is weird
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
    requires_any_of = [":not_kernel_extension"],
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
    requires_any_of = [":not_kernel_extension"],
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
    toolchains = [":target_thing"],
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
    name = "objc_fully_link_linker_param_file",
    actions = ["@rules_cc//cc/toolchains/actions:objc_fully_link"],
    args = ["@{param_file}"],
    format = {"param_file": "@rules_cc//cc/toolchains/variables:linker_param_file"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:linker_param_file",
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
        # ":objc_fully_link_linker_param_file", # FIXME: variable missing
    ],
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
    env = {
        "HEADER_PARSING_OUTPUT": "{output_file}",
    },
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

cc_toolchain(
    name = "foo",  # name = "cc-compiler-" + cpu,
    artifact_name_patterns = [":dylib_pattern"],
    compiler = "clang",
    # TODO: Use experimental_replace_legacy_action_config_features as long as ordering isn't an issue
    enabled_features = ENABLED_MARKERS + [
        # NOTE: ORDER MATTERS
        "@rules_cc//cc/toolchains/args/strip_flags:feature",
        ":__objc_executable_feature",
        ":__objc_fully_link_feature",
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
        ":objc_link_flag",
        ":pch",
        ":__apple_default_warnings",
        "@rules_cc//cc/toolchains/args/archiver_flags:feature",
        "@rules_cc//cc/toolchains/args/include_flags:feature",
        "@rules_cc//cc/toolchains/args/dependency_file:feature",
        ":serialized_diagnostics_file_wrapper",
        "@rules_cc//cc/toolchains/args/pic_flags:feature",
        "@rules_cc//cc/toolchains/args/preprocessor_defines:feature",
        "//crosstool/rules_based/pgo:fdo_instrument_wrapper",
        "//crosstool/rules_based/pgo:fdo_optimize_wrapper",
        "//crosstool/rules_based/pgo:autofdo_wrapper",
        ":lto_object_path",
        ":llvm_coverage_map_format_wrapper",
        ":gcc_coverage_map_format_wrapper",
        ":coverage_prefix_map",
        ":_coverage_prefix_map_absolute_sources_non_hermetic_wrapper",
        ":__apple_default_compiler_flags",
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
        "@rules_cc//cc/toolchains/args/compile_flags:user_compile_flags_feature",  # TODO: Switch to compile_flags:feature if ordering isn't an issue
        ":unfiltered_compile_flags_feature",
        "@rules_cc//cc/toolchains/args/compiler_input_flags:feature",
        "@rules_cc//cc/toolchains/args/compiler_output_flags:feature",
        "@rules_cc//cc/toolchains/args/linker_param_file:feature",
        "@rules_cc//cc/toolchains/args/soname_flags:feature",
        ":asan_wrapper",
        ":tsan_wrapper",
        ":ubsan_wrapper",
        ":default_sanitizer_flags",
        ":suppress_warnings_wrapper",
        ":treat_warnings_as_errors_wrapper",
        ":external_include_paths_wrapper",
        ":no_warn_duplicate_libraries",
    ] + select({
        ":no_xcode_version": [":__clt_env"],
        "//conditions:default": [":__xcode_env"],
    }),
    # args = toolhain_args,
    known_features = MARKER_FEATURES + [
        "@rules_cc//cc/toolchains/features:opt",
        "@rules_cc//cc/toolchains/features:dbg",
        "@rules_cc//cc/toolchains/features:fastbuild",
        ":coverage",
        ":kernel_extension",
        ":serialized_diagnostics_file",
        ":llvm_coverage_map_format",
        ":gcc_coverage_map_format",
        ":_coverage_prefix_map_absolute_sources_non_hermetic",
        ":asan",
        ":tsan",
        ":ubsan",
        ":generate_dsym_file",
        ":generate_linkmap",
        ":link_cocoa",
        ":dead_strip",
        ":suppress_warnings",
        ":treat_warnings_as_errors",
        ":external_include_paths",
        "//crosstool/rules_based/pgo:fdo_instrument",
        "//crosstool/rules_based/pgo:autofdo",
        "//crosstool/rules_based/pgo:fdo_optimize",
    ] + select({
        "@platforms//os:macos": [
            ":dynamic_linking_mode",
        ],
        "//conditions:default": [],
    }),
    make_variables = [":stack_frame_variable"],
    supports_header_parsing = True,
    supports_param_files = True,
    tool_map = "//crosstool/rules_based/tools",  # FIXME: tool_path_overrides
    visibility = ["//:__subpackages__"],
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
