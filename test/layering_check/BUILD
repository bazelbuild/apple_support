load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test", "objc_library")
load("//test/rules:action_command_line_test.bzl", "action_command_line_test")

package(features = ["layering_check"])

cc_library(
    name = "a",
    hdrs = ["a.h"],
)

cc_library(
    name = "b",
    hdrs = ["b.h"],
    deps = [":a"],
)

cc_test(
    name = "bad_layering_check",
    srcs = ["c.cpp"],
    tags = ["manual"],
    deps = [":b"],
)

cc_test(
    name = "disabled_bad_layering_check",
    srcs = ["c.cpp"],
    features = ["-layering_check"],
    deps = [":b"],
)

cc_test(
    name = "good_layering_check",
    srcs = ["c.cpp"],
    deps = [
        ":a",
        ":b",
    ],
)

# From Clang 14 on, -std=c++20 switches the driver to C++20 modules
# semantics: including a header a module map covers *non-textually* becomes
# "module 'cxx20_modular' is needed but has not been provided" -- unless the
# toolchain passes -fno-cxx-modules (//toolchain:no_cxx_modules_flags, gated
# on use_module_maps). wrapped_clang's generated map and the per-target maps
# Bazel writes are all-textual and immune, but the system module map of a
# hermetic toolchain driving this configuration is not.
cc_library(
    name = "cxx20_non_textual_module_map",
    srcs = ["modular.cpp"],
    hdrs = ["modular.h"],
    additional_compiler_inputs = ["cxx20.modulemap"],
    copts = [
        "-std=c++20",
        "-fmodule-map-file=$(execpath cxx20.modulemap)",
    ],
    # use_module_maps alone, without layering_check: strict-decluse would
    # (correctly) reject the include, since nothing declares a dependency on
    # the map's module. The fix is gated on use_module_maps, not on
    # layering_check itself.
    features = [
        "-layering_check",
        "use_module_maps",
    ],
)

build_test(
    name = "cxx20_non_textual_module_map_test",
    targets = [":cxx20_non_textual_module_map"],
)

# The flag is emitted exactly when use_module_maps is enabled: by itself, by
# way of layering_check, and never without. Note the build test above cannot
# fail under Xcode's clang, which does not switch to C++20 modules semantics
# the way upstream Clang 14+ does -- these assert the flag so the fix is
# visible under the tools this repo tests with.
action_command_line_test(
    name = "no_cxx_modules_flags_from_module_maps_test",
    expected_argv = [
        "-Xclang",
        "-fno-cxx-modules",
        "-Wno-module-import-in-extern-c",
    ],
    mnemonic = "CppCompile",
    tags = ["requires_rules_based_toolchain"],
    target_under_test = ":cxx20_non_textual_module_map",
)

action_command_line_test(
    name = "no_cxx_modules_flags_from_layering_check_test",
    expected_argv = [
        "-Xclang",
        "-fno-cxx-modules",
        "-Wno-module-import-in-extern-c",
    ],
    mnemonic = "CppCompile",
    tags = ["requires_rules_based_toolchain"],
    target_under_test = ":good_layering_check",
)

action_command_line_test(
    name = "no_cxx_modules_flags_off_without_module_maps_test",
    mnemonic = "CppCompile",
    not_expected_argv = ["-fno-cxx-modules"],
    tags = ["requires_rules_based_toolchain"],
    target_under_test = ":disabled_bad_layering_check",
)

objc_library(
    name = "bad_layering_check_objc",
    srcs = ["c.m"],
    tags = ["manual"],
    deps = [":b"],
)

build_test(
    name = "bad_layering_check_objc_test",
    tags = ["manual"],
    targets = [":bad_layering_check_objc"],
)

objc_library(
    name = "disabled_bad_layering_check_objc",
    srcs = ["c.m"],
    features = ["-layering_check"],
    deps = [":b"],
)

build_test(
    name = "disabled_bad_layering_check_objc_test",
    targets = [":disabled_bad_layering_check_objc"],
)

objc_library(
    name = "good_layering_check_objc",
    srcs = ["c.m"],
    deps = [
        ":a",
        ":b",
    ],
)

build_test(
    name = "good_layering_check_objc_test",
    targets = [":good_layering_check_objc"],
)
