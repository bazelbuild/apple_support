"""Test rule for linking with bazel's builtin Apple logic"""

load("//test:transitions.bzl", "apple_platform_split_transition")

_supports_extra_requested_features = hasattr(apple_common.platform_type, "visionos")

def _starlark_apple_binary_impl(ctx):
    extra_requested_features = []
    bazel_6_linkopts = []
    if ctx.attr.binary_type == "dylib":
        extra_requested_features.append("link_dylib")
        bazel_6_linkopts = ["-dynamiclib"]
    elif ctx.attr.binary_type == "loadable_bundle":
        extra_requested_features.append("link_bundle")
        bazel_6_linkopts = ["-bundle"]

    kwargs = {}
    if _supports_extra_requested_features:
        kwargs["extra_requested_features"] = extra_requested_features
    else:
        kwargs["extra_linkopts"] = bazel_6_linkopts

    link_result = apple_common.link_multi_arch_binary(
        ctx = ctx,
        stamp = ctx.attr.stamp,
        **kwargs
    )
    processed_binary = ctx.actions.declare_file(
        "{}_lipobin".format(ctx.label.name),
    )
    lipo_inputs = [output.binary for output in link_result.outputs]
    if len(lipo_inputs) > 1:
        apple_env = {}
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
        apple_env.update(apple_common.apple_host_system_env(xcode_config))
        apple_env.update(
            apple_common.target_apple_env(
                xcode_config,
                ctx.fragments.apple.single_arch_platform,
            ),
        )
        args = ctx.actions.args()
        args.add("-create")
        args.add_all(lipo_inputs)
        args.add("-output", processed_binary)
        ctx.actions.run(
            arguments = [args],
            env = apple_env,
            executable = "/usr/bin/lipo",
            execution_requirements = xcode_config.execution_info(),
            inputs = lipo_inputs,
            outputs = [processed_binary],
        )
    else:
        ctx.actions.symlink(
            target_file = lipo_inputs[0],
            output = processed_binary,
        )
    return [
        DefaultInfo(files = depset([processed_binary])),
        OutputGroupInfo(**link_result.output_groups),
        link_result.debug_outputs_provider,
    ]

# All of the attributes below, except for `stamp`, are required as part of the
# implied contract of `apple_common.link_multi_arch_binary` since it asks for
# attributes directly from the rule context. As these requirements are changed
# from implied attributes to function arguments, they can be removed.
starlark_apple_binary = rule(
    attrs = {
        "_child_configuration_dummy": attr.label(
            cfg = apple_platform_split_transition,
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
        "_xcode_config": attr.label(
            default = configuration_field(
                fragment = "apple",
                name = "xcode_config_label",
            ),
        ),
        "_xcrunwrapper": attr.label(
            cfg = "exec",
            default = Label("@bazel_tools//tools/objc:xcrunwrapper"),
            executable = True,
        ),
        "binary_type": attr.string(
            default = "executable",
            values = ["dylib", "executable", "loadable_bundle"],
        ),
        "bundle_loader": attr.label(),
        "deps": attr.label_list(
            cfg = apple_platform_split_transition,
        ),
        "dylibs": attr.label_list(),
        "linkopts": attr.string_list(),
        "minimum_os_version": attr.string(mandatory = True),
        "platform_type": attr.string(mandatory = True),
        "stamp": attr.int(default = -1, values = [-1, 0, 1]),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    fragments = ["apple", "objc", "cpp"],
    implementation = _starlark_apple_binary_impl,
)
