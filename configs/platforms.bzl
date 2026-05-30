"""Defines all the Apple CPUs and their constraints"""

APPLE_PLATFORMS_CONSTRAINTS = {
    "darwin_arm64": [
        "@platforms//os:macos",
        "@platforms//cpu:arm64",
        Label("//constraints:device"),
    ],
    "darwin_arm64e": [
        "@platforms//os:macos",
        "@platforms//cpu:arm64e",
        Label("//constraints:device"),
    ],
    "darwin_x86_64": [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
        Label("//constraints:device"),
    ],
    "ios_arm64": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64",
        Label("//constraints:device"),
    ],
    "ios_arm64e": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64e",
        Label("//constraints:device"),
    ],
    "ios_x86_64": [
        "@platforms//os:ios",
        "@platforms//cpu:x86_64",
        Label("//constraints:simulator"),
    ],
    "ios_sim_arm64": [
        "@platforms//os:ios",
        "@platforms//cpu:arm64",
        Label("//constraints:simulator"),
    ],
    "tvos_arm64": [
        "@platforms//os:tvos",
        "@platforms//cpu:arm64",
        Label("//constraints:device"),
    ],
    "tvos_x86_64": [
        "@platforms//os:tvos",
        "@platforms//cpu:x86_64",
        Label("//constraints:simulator"),
    ],
    "tvos_sim_arm64": [
        "@platforms//os:tvos",
        "@platforms//cpu:arm64",
        Label("//constraints:simulator"),
    ],
    "visionos_arm64": [
        "@platforms//os:visionos",
        "@platforms//cpu:arm64",
        Label("//constraints:device"),
    ],
    "visionos_sim_arm64": [
        "@platforms//os:visionos",
        "@platforms//cpu:arm64",
        Label("//constraints:simulator"),
    ],
    "watchos_arm64": [
        "@platforms//os:watchos",
        "@platforms//cpu:arm64",
        Label("//constraints:simulator"),
    ],
    "watchos_device_arm64": [
        "@platforms//os:watchos",
        "@platforms//cpu:arm64",
        Label("//constraints:device"),
    ],
    "watchos_device_arm64e": [
        "@platforms//os:watchos",
        "@platforms//cpu:arm64e",
        Label("//constraints:device"),
    ],
    "watchos_arm64_32": [
        "@platforms//os:watchos",
        "@platforms//cpu:arm64_32",
        Label("//constraints:device"),
    ],
    "watchos_x86_64": [
        "@platforms//os:watchos",
        "@platforms//cpu:x86_64",
        Label("//constraints:simulator"),
    ],
}

APPLE_DEVICE_CPUS = [
    cpu
    for cpu, constraints in APPLE_PLATFORMS_CONSTRAINTS.items()
    if Label("//constraints:device") in constraints
]

APPLE_SIMULATOR_CPUS = [
    cpu
    for cpu, constraints in APPLE_PLATFORMS_CONSTRAINTS.items()
    if Label("//constraints:simulator") in constraints
]

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
    "watchos_device_arm64": "watchos_device_arm64",
    "watchos_device_arm64e": "watchos_device_arm64e",
    "watchos_x86_64": "watchos_x86_64",
}
