"""Tests for coverage instrumentation and runtime selection."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

_COMPILE_FLAGS = {
    "gcc": ["-fprofile-arcs", "-ftest-coverage"],
    "llvm": ["-fprofile-instr-generate", "-fcoverage-mapping"],
}

def _coverage_test_impl(ctx):
    env = analysistest.begin(ctx)
    compile_actions = [
        action
        for action in analysistest.target_actions(env)
        if action.mnemonic in ["CppCompile", "ObjcCompile"]
    ]
    asserts.true(env, bool(compile_actions), "Expected a compile action")
    for action in compile_actions:
        for coverage_format, flags in _COMPILE_FLAGS.items():
            for flag in flags:
                asserts.equals(
                    env,
                    ctx.attr.instrumented and coverage_format == ctx.attr.coverage_format,
                    flag in action.argv,
                    "Unexpected presence or absence of " + flag,
                )
        for flag in [
            "-fcoverage-prefix-map=__BAZEL_EXECUTION_ROOT__=.",
            "-fcoverage-prefix-map=__BAZEL_EXECUTION_ROOT__=__BAZEL_EXECUTION_ROOT_CANONICAL__",
        ]:
            asserts.equals(env, ctx.attr.instrumented, flag in action.argv, flag)

    for action in analysistest.target_actions(env):
        if action.mnemonic == "CppLink":
            # Even an uninstrumented binary may link instrumented dependencies.
            runtime_flag = "--coverage" if ctx.attr.coverage_format == "gcc" else "-fprofile-instr-generate"
            asserts.true(env, runtime_flag in action.argv, "Missing coverage runtime: " + runtime_flag)
    return analysistest.end(env)

def _make_coverage_test(coverage_format, mode):
    return analysistest.make(
        _coverage_test_impl,
        attrs = {
            "coverage_format": attr.string(default = coverage_format),
            "instrumented": attr.bool(default = mode != "uninstrumented"),
        },
        config_settings = {
            "//command_line_option:collect_code_coverage": True,
            # Exclude implicit dependencies too, since instrumented direct
            # dependencies also cause the binary itself to be instrumented.
            "//command_line_option:instrumentation_filter": "-.*" if mode == "uninstrumented" else "//test/test_data",
            "//command_line_option:features": [
                coverage_format + "_coverage_map_format",
                "-" + ("llvm" if coverage_format == "gcc" else "gcc") + "_coverage_map_format",
                "_coverage_prefix_map_absolute_sources_non_hermetic",
            ],
        },
    )

_gcc_legacy_test = _make_coverage_test("gcc", "legacy")
_gcc_instrumented_test = _make_coverage_test("gcc", "instrumented")
_gcc_uninstrumented_test = _make_coverage_test("gcc", "uninstrumented")
_llvm_legacy_test = _make_coverage_test("llvm", "legacy")
_llvm_instrumented_test = _make_coverage_test("llvm", "instrumented")
_llvm_uninstrumented_test = _make_coverage_test("llvm", "uninstrumented")

def coverage_test_suite(name):
    """Tests coverage for both formats, including the legacy feature fallback.

    Args:
        name: The test suite name and prefix for its tests.
    """
    if bazel_features.cc.cc_common_is_in_rules_cc:
        test_rules = {
            "gcc_instrumented": _gcc_instrumented_test,
            "gcc_uninstrumented": _gcc_uninstrumented_test,
            "llvm_instrumented": _llvm_instrumented_test,
            "llvm_uninstrumented": _llvm_uninstrumented_test,
        }
    else:
        test_rules = {
            "gcc_legacy": _gcc_legacy_test,
            "llvm_legacy": _llvm_legacy_test,
        }

    tests = []
    for mode, test_rule in test_rules.items():
        for target in ["c_main", "cc_test_binary", "objc_lib", "objcpp_lib"]:
            test_name = "{}_{}_{}_test".format(name, mode, target)
            test_rule(
                name = test_name,
                target_under_test = "//test/test_data:" + target,
                tags = [name, "requires_rules_based_toolchain"],
            )
            tests.append(test_name)

    native.test_suite(name = name, tests = tests)
