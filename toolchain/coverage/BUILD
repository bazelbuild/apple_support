load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:feature_constraint.bzl", "cc_feature_constraint")
load("//toolchain:features.bzl", "enableable_feature", "negatable_feature")

package(default_visibility = ["//visibility:public"])

_COVERAGE_COMPILE_ACTIONS = [
    # TODO: Should all compile actions be here?
    "@rules_cc//cc/toolchains/actions:c_compile",
    "@rules_cc//cc/toolchains/actions:cpp_compile",
    "@rules_cc//cc/toolchains/actions:cpp_module_compile",
    "@rules_cc//cc/toolchains/actions:objc_compile",
    "@rules_cc//cc/toolchains/actions:objcpp_compile",
    "@rules_cc//cc/toolchains/actions:preprocess_assemble",
]

cc_feature(
    name = "coverage",
    overrides = "@rules_cc//cc/toolchains/features/legacy:coverage",
)

cc_feature(
    name = "coverage_enabled",
    feature_name = "coverage_enabled",
)

cc_feature(
    name = "coverage_instrumented",
    feature_name = "coverage_instrumented",
)

# TODO: Remove when we drop bazel 8.x support
cc_feature_constraint(
    name = "legacy_coverage",
    all_of = [":coverage"],
    none_of = [":coverage_enabled"],
)

_COVERAGE_COMPILE_FEATURES = [
    ":coverage_instrumented",
    ":legacy_coverage",
]

cc_args(
    name = "gcc_coverage_map_format_compile_args",
    actions = _COVERAGE_COMPILE_ACTIONS,
    args = [
        "-fprofile-arcs",
        "-ftest-coverage",
        "-g",
    ],
    requires_any_of = _COVERAGE_COMPILE_FEATURES,
)

cc_args(
    name = "gcc_coverage_data_file",
    actions = _COVERAGE_COMPILE_ACTIONS,
    env = {"GCOV_GCNO_FILE": "{gcov_gcno_file}"},
    format = {"gcov_gcno_file": "@rules_cc//cc/toolchains/variables:gcov_gcno_file"},
    requires_any_of = _COVERAGE_COMPILE_FEATURES,
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
        ":gcc_coverage_data_file",
    ],
    overrides = "@rules_cc//cc/toolchains/features/legacy:gcc_coverage_map_format",
    requires_any_of = [
        ":coverage_enabled",
        ":coverage",
    ],
)

cc_args(
    name = "llvm_coverage_map_format_compile_args",
    actions = _COVERAGE_COMPILE_ACTIONS,
    args = [
        "-fprofile-instr-generate",
        "-fcoverage-mapping",
        "-g",
    ],
    requires_any_of = _COVERAGE_COMPILE_FEATURES,
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
    requires_any_of = [
        ":coverage_enabled",
        ":coverage",
    ],
)

negatable_feature(
    name = "coverage_prefix_map",
    actions = _COVERAGE_COMPILE_ACTIONS,
    args = ["-fcoverage-prefix-map=__BAZEL_EXECUTION_ROOT__=."],
    requires_any_of = _COVERAGE_COMPILE_FEATURES,
)

cc_args(
    name = "_coverage_prefix_map_absolute_sources_non_hermetic_args",
    actions = _COVERAGE_COMPILE_ACTIONS,
    args = ["-fcoverage-prefix-map=__BAZEL_EXECUTION_ROOT__=__BAZEL_EXECUTION_ROOT_CANONICAL__"],
    env = {"COVERAGE_PREFIX_MAP_USE_ABSOLUTE_CWD_PATH": "1"},
    requires_any_of = _COVERAGE_COMPILE_FEATURES,
)

enableable_feature(
    name = "_coverage_prefix_map_absolute_sources_non_hermetic",
    custom_args = [":_coverage_prefix_map_absolute_sources_non_hermetic_args"],
    requires_any_of = [
        ":coverage_enabled",
        ":coverage",
    ],
)
