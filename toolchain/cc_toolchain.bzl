"""Create a clang toolchain that optionally supports Apple platforms."""

load("@rules_cc//cc/toolchains:toolchain.bzl", _cc_toolchain = "cc_toolchain")

# NOTE: Ideally this would be limited but there is a huge variety of repo names
# used by rules_swift for this
visibility("public")

def cc_toolchain(
        *,
        name,
        target,
        module_map,
        sysroot_feature,
        supports_header_parsing,
        tool_map,
        target_from_xcode = True,
        flags_from_env = True,
        coverage_instrumentation = True,
        apple_linker_flags = True,
        extra_enabled_features = None,
        extra_known_features = None,
        extra_include_directories = None,
        dynamic_runtime_lib = None,
        static_runtime_lib = None):
    """Defines a C/C++ toolchain with Apple defaults on Apple platforms.

    Args:
        name: The name of the toolchain target.
        target: The target triple for the toolchain.
        module_map: Module map artifact for modular builds.
        supports_header_parsing: Whether header parsing actions are supported.
        sysroot_feature: The enabled feature that supplies the toolchain's sysroot.
        tool_map: The `cc_tool_map` that supplies the toolchain's tools. On
            Apple platforms some of the toolchain's args are not compiler flags
            but part of `wrapped_clang`'s protocol -- the `__BAZEL_*` path
            placeholders, and the sentinel args `STRIP_DEBUG_SYMBOLS`,
            `LINKED_BINARY=...` and `DSYM_HINT_DSYM_PATH=...` that stand for
            work the tool does around the compiler. A `tool_map` that does not
            drive `wrapped_clang` itself has to supply a tool that resolves the
            placeholders and acts on the sentinels the same way.
        target_from_xcode: Whether to take the target triple from the Xcode
            configuration on Apple platforms, which is what this repo's own
            toolchain does and which ignores `target`. Set it to False to use
            `target` on every platform, as a toolchain that pins its own triple
            (and passes its own deployment-target flag) needs.
        flags_from_env: Whether to append the flags read from `BAZEL_COPTS`,
            `BAZEL_CONLYOPTS`, `BAZEL_CXXOPTS` and `BAZEL_LINKOPTS`. Defaults to
            True. Note that `BAZEL_CXXOPTS` defaults to `-std=c++17`, so a
            toolchain that sets its own C++ standard has to turn this off --
            the environment is read once per build, so it also cannot differ
            between two toolchains in the same workspace.
        apple_linker_flags: Whether to pass the link flags that only Apple's
            `ld64` accepts -- `-no_warn_duplicate_libraries` and
            `-reproducible`. Defaults to True, which is right for a toolchain
            that links with the `ld` from Xcode. `ld64.lld` rejects an argument
            it does not know, so a toolchain linking with a bundled `ld64.lld`
            has to turn this off for the LLVM versions that predate it.
        coverage_instrumentation: Whether to contribute the gcc and llvm
            coverage-map-format instrumentation flags. Defaults to True. Set it
            to False to instrument from the consumer's own args instead --
            which format Bazel picks is otherwise up to Bazel, and the gcc one
            is the default.
        extra_enabled_features: A `cc_feature_set` of extra features to enable,
            in addition to the `//toolchain:extra_enabled_features` flag. A
            toolchain that is generated more than once per workspace needs this
            as an attribute, since the flag is global and cannot differ between
            two toolchains.
        extra_known_features: A `cc_feature_set` of extra features to make
            known, in addition to the `//toolchain:extra_known_features` flag.
        extra_include_directories: A `cc_args` of extra include directories, in
            addition to the `//toolchain:extra_include_directories` flag.
        dynamic_runtime_lib: Passed through to `cc_toolchain`. The dynamic
            library to link when `static_link_cpp_runtimes` is enabled, which
            is how a sanitizer runtime dylib reaches a test's runfiles.
        static_runtime_lib: Passed through to `cc_toolchain`.
    """
    extra_enabled_features = [extra_enabled_features] if extra_enabled_features else []
    extra_known_features = [extra_known_features] if extra_known_features else []
    extra_include_directories = [extra_include_directories] if extra_include_directories else []
    _cc_toolchain(
        name = name,
        args = [
            # An allowlist of the directories Xcode and the command line tools
            # install into. It only widens what Bazel will accept as a builtin
            # include, so it cannot break a build that does not need it, and
            # any toolchain compiling against an Xcode SDK does need it.
            Label("@apple_support_toolchain_env//:include_directories_from_xcode"),
            Label("//toolchain:extra_include_directories"),
        ] + extra_include_directories + select({
            Label("//configs:apple"): [Label("//toolchain:apple_env")],
            "//conditions:default": [],
        }),
        artifact_name_patterns = select({
            Label("//configs:apple"): [Label("//toolchain:dylib_pattern")],
            "//conditions:default": [],
        }),
        compiler = "clang",
        # TODO: Use experimental_replace_legacy_action_config_features as long as ordering isn't an issue
        enabled_features = [
            # NOTE: ORDER MATTERS
            Label("//toolchain:_enabled_markers"),
            Label("@rules_cc//cc/toolchains/args/layering_check:module_maps"),  # NOTE: This is a marker feature
            Label("@rules_cc//cc/toolchains/args/strip_flags:feature"),
            Label("//toolchain/objc:__objc_executable_feature"),
            Label("//toolchain/objc:__objc_fully_link_feature"),
            Label("//toolchain:__header_parsing_flags"),  # NOTE: Must come before input files
        ] + select({
            Label("//configs:apple"): [
                Label("//toolchain:link_libc++"),
            ],
            "//conditions:default": [],
        }) + [
            Label("//toolchain:default_compile_flags_feature"),
            Label("//toolchain:ns_block_assertions"),
            Label("//toolchain:debug_prefix_map_pwd_is_dot"),
            Label("//toolchain:remap_xcode_path"),
            Label("//toolchain:generate_dsym_file_wrapper"),
            Label("//toolchain:generate_linkmap_wrapper"),
        ] + select({
            Label("//configs:apple"): [Label("//toolchain:oso_prefix_is_pwd")],
            "//conditions:default": [],
        }) + select({
            Label("//configs:apple"): [Label("//toolchain:strip_debug_symbols")],
            "//conditions:default": [Label("@rules_cc//cc/toolchains/args/strip_debug_symbols:feature")],
        }) + [
            Label("@rules_cc//cc/toolchains/args/shared_flag:feature"),
            Label("//toolchain:kernel_extension_wrapper"),
        ] + select({
            Label("//configs:apple"): [Label("//toolchain:output_execpath_flags")],
            "//conditions:default": [Label("//toolchain:linux_output_execpath_flags")],
        }) + [
            Label("@rules_cc//cc/toolchains/args/runtime_library_search_directories:feature"),
            Label("@rules_cc//cc/toolchains/args/library_search_directories:feature"),
            Label("@rules_cc//cc/toolchains/args/libraries_to_link:feature"),
            Label("//toolchain/objc:objc_link_flag"),
            Label("//toolchain:pch"),
            Label("//toolchain/objc:__apple_default_warnings"),
        ] + select({
            Label("//configs:apple"): [Label("//toolchain:__archiver_flags")],
            "//conditions:default": [Label("@rules_cc//cc/toolchains/args/archiver_flags:feature")],
        }) + [
            Label("@rules_cc//cc/toolchains/args/include_flags:feature"),
            Label("@rules_cc//cc/toolchains/args/dependency_file:feature"),
            Label("//toolchain:serialized_diagnostics_file_wrapper"),
            Label("@rules_cc//cc/toolchains/args/pic_flags:feature"),
            Label("@rules_cc//cc/toolchains/args/preprocessor_defines:feature"),
            Label("//toolchain/pgo:fdo_instrument_wrapper"),
            Label("//toolchain/pgo:fdo_optimize_wrapper"),
            Label("//toolchain/pgo:autofdo_wrapper"),
        ] + select({
            Label("//configs:apple"): [Label("//toolchain:lto_object_path")],
            "//conditions:default": [],
        }) + ([
            Label("//toolchain/coverage:llvm_coverage_map_format_wrapper"),
            Label("//toolchain/coverage:gcc_coverage_map_format_wrapper"),
        ] if coverage_instrumentation else []) + [
            Label("//toolchain/coverage:coverage_prefix_map"),
            Label("//toolchain/coverage:_coverage_prefix_map_absolute_sources_non_hermetic_wrapper"),
            Label("//toolchain/objc:__apple_default_compiler_flags"),
        ] + [sysroot_feature] + [
            Label("//toolchain:headerpad"),
            Label("@rules_cc//cc/toolchains/args/objc_arc_flags:feature"),
            Label("//toolchain:user_link_flags"),  # TODO: Switch to upstream feature
        ] + ([
            Label("@apple_support_toolchain_env//:linkopts_from_env"),  # TODO: Join with the copts below
        ] if flags_from_env else []) + [
            Label("//toolchain:default_required_flags") if target_from_xcode else Label("//toolchain:plain_required_flags"),
            Label("//toolchain:__apply_simulator_compiler_flags"),
            Label("//toolchain/sanitizers:asan_wrapper"),
            Label("//toolchain/sanitizers:tsan_wrapper"),
            Label("//toolchain/sanitizers:ubsan_wrapper"),
            Label("//toolchain/sanitizers:default_sanitizer_flags"),
        ] + ([
            Label("@apple_support_toolchain_env//:copts_from_env"),
        ] if flags_from_env else []) + [
            Label("//toolchain:default_link_flags"),
        ] + select({
            Label("//toolchain:opt_mode"): [Label("//toolchain:dead_strip")],
            "//conditions:default": [],
        }) + [
            Label("//toolchain:no_deduplicate"),
            Label("//toolchain:function_sections"),
            Label("//toolchain:dead_strip_wrapper"),
            Label("//toolchain:apply_implicit_frameworks"),
            Label("//toolchain:link_cocoa_wrapper"),
            Label("//toolchain:extra_enabled_features"),
        ] + extra_enabled_features + [
            Label("@rules_cc//cc/toolchains/args/compile_flags:user_compile_flags_feature"),  # TODO: Switch to compile_flags:feature if ordering isn't an issue
            Label("//toolchain:unfiltered_compile_flags"),
            Label("@rules_cc//cc/toolchains/args/compiler_input_flags:feature"),
            Label("@rules_cc//cc/toolchains/args/compiler_output_flags:feature"),
            Label("@rules_cc//cc/toolchains/args/linker_param_file:feature"),
            Label("@rules_cc//cc/toolchains/args/soname_flags:feature"),
            Label("//toolchain:suppress_warnings_wrapper"),
            Label("//toolchain:treat_warnings_as_errors_wrapper"),
        ] + (select({
            Label("//configs:apple"): [
                Label("//toolchain:no_warn_duplicate_libraries"),
                Label("//toolchain:reproducible_linker_flag"),
            ],
            "//conditions:default": [],
        }) if apple_linker_flags else []) + [
            Label("//toolchain:external_include_paths_wrapper"),
        ] + select({
            Label("//configs:apple"): [
                Label("@apple_support_toolchain_env//:off_by_default_layering_check_enabled_features"),
            ],
            "//conditions:default": [],
        }),
        known_features = [
            Label("//toolchain:_marker_features"),
            Label("//toolchain:opt"),
            Label("//toolchain:dbg"),
            Label("//toolchain:fastbuild"),
            Label("//toolchain/coverage"),
            Label("//toolchain:kernel_extension"),
            Label("//toolchain:serialized_diagnostics_file"),
        ] + ([
            Label("//toolchain/coverage:llvm_coverage_map_format"),
            Label("//toolchain/coverage:gcc_coverage_map_format"),
        ] if coverage_instrumentation else []) + [
            Label("//toolchain/coverage:_coverage_prefix_map_absolute_sources_non_hermetic"),
            Label("//toolchain/sanitizers:asan"),
            Label("//toolchain/sanitizers:tsan"),
            Label("//toolchain/sanitizers:ubsan"),
            Label("//toolchain:generate_dsym_file"),
            Label("//toolchain:generate_linkmap"),
            Label("//toolchain:link_cocoa"),
            Label("//toolchain:dead_strip"),
            Label("//toolchain:suppress_warnings"),
            Label("//toolchain:treat_warnings_as_errors"),
            Label("//toolchain:external_include_paths"),
            Label("//toolchain/pgo:fdo_instrument"),
            Label("//toolchain/pgo:autofdo"),
            Label("//toolchain/pgo:fdo_optimize"),
            Label("@apple_support_toolchain_env//:off_by_default_layering_check_known_features"),
        ] + extra_known_features + [
            Label("//toolchain:extra_known_features"),
            Label("@rules_cc//cc/toolchains/args/layering_check:use_module_maps"),  # TODO: https://github.com/bazelbuild/rules_cc/pull/657
        ] + select({
            Label("@platforms//os:macos"): [
                Label("//toolchain:dynamic_linking_mode"),
            ],
            "//conditions:default": [],
        }),
        legacy_tools = [
            Label("//toolchain:gcov"),
        ],
        make_variables = select({
            Label("//configs:apple"): [Label("//toolchain:stack_frame_variable")],
            "//conditions:default": [],
        }),
        dynamic_runtime_lib = dynamic_runtime_lib,
        static_runtime_lib = static_runtime_lib,
        module_map = module_map,
        supports_header_parsing = supports_header_parsing,
        supports_param_files = True,
        target_system_name = target,
        tool_map = tool_map,
        toolchains = select({
            Label("//configs:apple"): [Label("//toolchain:dynamic_toolchain_info")],
            "//conditions:default": [],
        }),
        visibility = ["//visibility:public"],
    )
