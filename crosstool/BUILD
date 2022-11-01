package(default_visibility = ["//visibility:public"])

# Files which shouldn't be publicly visible and dependencies of all objc_* or ios_* rules should be excluded.
exports_files(glob(
    ["**"],
))

cc_binary(
    name = "wrapped_clang",
    testonly = True,
    srcs = [
        "wrapped_clang.cc",
    ],
)
