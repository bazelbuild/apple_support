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
