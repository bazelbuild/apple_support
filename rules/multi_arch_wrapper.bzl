"""
Wrap a macOS tool in a multi-arch transition. This is useful for building fat
binaries to share caches between Apple Silicon and Intel machines. This
behavior requires Xcode 12
"""

# NOTE: This lives in apple_support instead of rules_apple so that rules_swift
# can depend on it

def _force_multi_arch_transition_impl(settings, attr):
    return {"//command_line_option:macos_cpus": "arm64,x86_64"}

_force_multi_arch_transition = transition(
    implementation = _force_multi_arch_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:macos_cpus"],
)

def _multi_arch_wrapper_impl(ctx):
    link_result = apple_common.link_multi_arch_binary(ctx = ctx)
    return [
        DefaultInfo(executable = link_result.binary_provider.binary),
        link_result.binary_provider,
    ]

multi_arch_wrapper = rule(
    implementation = _multi_arch_wrapper_impl,
    cfg = _force_multi_arch_transition,
    attrs = {
        "deps": attr.label_list(
            cfg = apple_common.multi_arch_split,
            mandatory = True,
        ),
        "minimum_os_version": attr.string(mandatory = True),
        # Implementation details
        "platform_type": attr.string(default = "macos"),
        "binary_type": attr.string(default = "executable"),
        "bundle_loader": attr.label(
            providers = [[apple_common.AppleExecutableBinary]],
        ),
        "_child_configuration_dummy": attr.label(
            cfg = apple_common.multi_arch_split,
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
        "_xcode_config": attr.label(
            default = configuration_field(
                fragment = "apple",
                name = "xcode_config_label",
            ),
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        # xcrunwrapper is no longer used by rules_apple, but the underlying implementation of
        # apple_common.link_multi_arch_binary requires this attribute.
        # TODO(b/117932394): Remove this attribute once Bazel no longer uses xcrunwrapper.
        "_xcrunwrapper": attr.label(
            cfg = "host",
            executable = True,
            default = Label("@bazel_tools//tools/objc:xcrunwrapper"),
        ),
    },
    fragments = ["apple", "objc", "cpp"],
    executable = True,
)
