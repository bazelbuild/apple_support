"""Defines all the Apple CPUs and their constraints"""

APPLE_PLATFORMS_CONSTRAINTS = {
    "darwin_arm64": [
        "@platforms//os:macos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:device",
    ],
    "darwin_arm64e": [
        "@platforms//os:macos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:device",
    ],
    "darwin_x86_64": [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
        "@build_bazel_apple_support//constraints:device",
    ],
    "ios_arm64": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:device",
    ],
    "ios_arm64e": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:device",
    ],
    "ios_armv7": [
        "@platforms//os:ios",
        "@platforms//cpu:armv7",
        "@build_bazel_apple_support//constraints:device",
    ],
    "ios_i386": [
        "@platforms//os:ios",
        "@platforms//cpu:i386",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "ios_x86_64": [
        "@platforms//os:ios",
        "@platforms//cpu:x86_64",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "ios_sim_arm64": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "tvos_arm64": [
        "@platforms//os:tvos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:device",
    ],
    "tvos_x86_64": [
        "@platforms//os:tvos",
        "@platforms//cpu:x86_64",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "tvos_sim_arm64": [
        "@platforms//os:tvos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "watchos_arm64": [
        "@platforms//os:watchos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "watchos_arm64_32": [
        "@platforms//os:watchos",
        "@platforms//cpu:arm64_32",
        "@build_bazel_apple_support//constraints:device",
    ],
    "watchos_armv7k": [
        "@platforms//os:watchos",
        "@platforms//cpu:armv7k",
        "@build_bazel_apple_support//constraints:device",
    ],
    "watchos_i386": [
        "@platforms//os:watchos",
        "@platforms//cpu:i386",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "watchos_x86_64": [
        "@platforms//os:watchos",
        "@platforms//cpu:x86_64",
        "@build_bazel_apple_support//constraints:simulator",
    ],
}
