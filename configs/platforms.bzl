"""Defines all the Apple CPUs and their constraints"""

APPLE_PLATFORMS_CONSTRAINTS = {
    "darwin_arm64": [
        "@platforms//os:macos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "darwin_arm64e": [
        "@platforms//os:macos",
        "@platforms//cpu:arm64e",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "darwin_x86_64": [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "ios_arm64": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "ios_arm64e": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64e",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "ios_x86_64": [
        "@platforms//os:ios",
        "@platforms//cpu:x86_64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "ios_sim_arm64": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "tvos_arm64": [
        "@platforms//os:tvos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "tvos_x86_64": [
        "@platforms//os:tvos",
        "@platforms//cpu:x86_64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "tvos_sim_arm64": [
        "@platforms//os:tvos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "visionos_arm64": [
        "@platforms//os:visionos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "visionos_sim_arm64": [
        "@platforms//os:visionos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "watchos_arm64": [
        "@platforms//os:watchos",
        "@platforms//cpu:arm64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:simulator",
    ],
    "watchos_arm64_32": [
        "@platforms//os:watchos",
        "@platforms//cpu:arm64_32",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "watchos_armv7k": [
        "@platforms//os:watchos",
        "@platforms//cpu:armv7k",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:device",
    ],
    "watchos_x86_64": [
        "@platforms//os:watchos",
        "@platforms//cpu:x86_64",
        "@build_bazel_apple_support//constraints:apple",
        "@build_bazel_apple_support//constraints:simulator",
    ],
}

CPU_TO_DEFAULT_PLATFORM_NAME = {
    "darwin_arm64": "macos_arm64",
    "darwin_arm64e": "macos_arm64e",
    "darwin_x86_64": "macos_x86_64",
    "ios_arm64": "ios_arm64",
    "ios_arm64e": "ios_arm64e",
    "ios_x86_64": "ios_x86_64",
    "ios_sim_arm64": "ios_sim_arm64",
    "tvos_arm64": "tvos_arm64",
    "tvos_x86_64": "tvos_x86_64",
    "tvos_sim_arm64": "tvos_sim_arm64",
    "visionos_arm64": "visionos_arm64",
    "visionos_sim_arm64": "visionos_sim_arm64",
    "watchos_arm64": "watchos_arm64",
    "watchos_arm64_32": "watchos_arm64_32",
    "watchos_armv7k": "watchos_armv7k",
    "watchos_x86_64": "watchos_x86_64",
}
