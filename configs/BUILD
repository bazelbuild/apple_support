load("@bazel_skylib//lib:selects.bzl", "selects")

package(default_visibility = ["//visibility:public"])

selects.config_setting_group(
    name = "apple",
    match_any = [
        ":darwin",
        ":darwin_arm64",
        ":darwin_x86_64",
        ":ios_arm64",
        ":ios_arm64e",
        ":ios_armv7",
        ":ios_armv7s",
        ":ios_i386",
        ":ios_sim_arm64",
        ":ios_x86_64",
    ],
)

# Configuration settings to make doing selects for Apple vs non-Apple platforms
# easier. More details: https://docs.bazel.build/versions/master/configurable-attributes.html#config_settingaliasing
config_setting(
    name = "darwin",
    values = {"cpu": "darwin"},
)

config_setting(
    name = "darwin_x86_64",
    values = {"cpu": "darwin_x86_64"},
)

config_setting(
    name = "darwin_arm64",
    values = {"cpu": "darwin_arm64"},
)

config_setting(
    name = "ios_i386",
    values = {"cpu": "ios_i386"},
)

config_setting(
    name = "ios_x86_64",
    values = {"cpu": "ios_x86_64"},
)

config_setting(
    name = "ios_armv7",
    values = {"cpu": "ios_armv7"},
)

config_setting(
    name = "ios_armv7s",
    values = {"cpu": "ios_armv7s"},
)

config_setting(
    name = "ios_arm64",
    values = {"cpu": "ios_arm64"},
)

config_setting(
    name = "ios_sim_arm64",
    values = {"cpu": "ios_sim_arm64"},
)

config_setting(
    name = "ios_arm64e",
    values = {"cpu": "ios_arm64e"},
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
