load("@rules_cc//cc/toolchains:mutually_exclusive_category.bzl", "cc_mutually_exclusive_category")
load("//toolchain:features.bzl", "enableable_feature")

package(default_visibility = ["//:__subpackages__"])

cc_mutually_exclusive_category(
    name = "profile",
)

enableable_feature(
    name = "fdo_instrument",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
        "@rules_cc//cc/toolchains/actions:cpp_link_dynamic_library",
        "@rules_cc//cc/toolchains/actions:cpp_link_executable",
    ],
    args = [
        "-fprofile-generate={fdo_instrument_path}",
        "-fno-data-sections",
    ],
    format = {"fdo_instrument_path": "@rules_cc//cc/toolchains/variables:fdo_instrument_path"},
    mutually_exclusive = [":profile"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:fdo_instrument",
    requires_not_none = "@rules_cc//cc/toolchains/variables:fdo_instrument_path",
)

enableable_feature(
    name = "fdo_optimize",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
    ],
    args = [
        "-fprofile-use={fdo_profile_path}",
        "-Wno-profile-instr-unprofiled",
        "-Wno-profile-instr-out-of-date",
        "-fprofile-correction",
    ],
    format = {"fdo_profile_path": "@rules_cc//cc/toolchains/variables:fdo_profile_path"},
    mutually_exclusive = [":profile"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:fdo_optimize",
    requires_not_none = "@rules_cc//cc/toolchains/variables:fdo_profile_path",
)

enableable_feature(
    name = "autofdo",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
    ],
    args = [
        "-fauto-profile={fdo_profile_path}",
        "-fprofile-correction",
    ],
    format = {"fdo_profile_path": "@rules_cc//cc/toolchains/variables:fdo_profile_path"},
    mutually_exclusive = [":profile"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:autofdo",
    requires_not_none = "@rules_cc//cc/toolchains/variables:fdo_profile_path",
)
