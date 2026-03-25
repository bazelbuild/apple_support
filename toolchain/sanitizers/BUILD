load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:feature_constraint.bzl", "cc_feature_constraint")
load("//toolchain:features.bzl", "enableable_feature")

package(default_visibility = ["//toolchain:__pkg__"])

_LIMITED_COMPILE_ACTIONS = [
    "@rules_cc//cc/toolchains/actions:c_compile",
    "@rules_cc//cc/toolchains/actions:cpp_compile",
    "@rules_cc//cc/toolchains/actions:objc_compile",
    "@rules_cc//cc/toolchains/actions:objcpp_compile",
]

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

cc_feature_constraint(
    name = "not_asan",
    none_of = [":asan"],
)

cc_args(
    name = "no_asan_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = ["-D_FORTIFY_SOURCE=1"],
    requires_any_of = ["//toolchain/sanitizers:not_asan"],
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
