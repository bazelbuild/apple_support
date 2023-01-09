sh_library(
    name = "bashunit",
    testonly = True,
    srcs = [
        "integration_test_setup.sh",
        "testenv.sh",
        "unittest.bash",
        "unittest_utils.sh",
    ],
)

sh_library(
    name = "apple_common",
    testonly = True,
    srcs = ["apple_common.sh"],
)

sh_test(
    name = "objc_test",
    size = "large",
    srcs = ["objc_test.sh"],
    deps = [
        ":apple_common",
        ":bashunit",
    ],
)

sh_test(
    name = "apple_test",
    srcs = ["apple_test.sh"],
    data = [
        ":apple_common",
        ":bashunit",
    ],
)
