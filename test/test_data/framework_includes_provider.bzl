"""Rule that provides CcInfo with framework_includes for testing."""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _framework_includes_lib_impl(ctx):
    return [
        CcInfo(
            compilation_context = cc_common.create_compilation_context(
                framework_includes = depset(ctx.attr.framework_includes),
            ),
        ),
    ]

framework_includes_lib = rule(
    implementation = _framework_includes_lib_impl,
    attrs = {
        "framework_includes": attr.string_list(),
    },
)
