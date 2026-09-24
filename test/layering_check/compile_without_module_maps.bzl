"""A rule that configures the C++ toolchain like rules that don't support module maps do."""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

_COMPILE_ACTIONS = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.objc_compile,
    ACTION_NAMES.objcpp_compile,
]

def _compile_without_module_maps_impl(ctx):
    # Mirrors rules that reuse the C++ toolchain to compile sources of another language, such as
    # cgo sources in rules_go: they do not generate module maps and thus declare the module_maps
    # feature as unsupported, while still picking up features such as layering_check from the
    # command line or the package.
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features + ["module_maps"],
    )
    variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
    )
    for action_name in _COMPILE_ACTIONS:
        # Fails if a feature references a variable that is only available with module maps.
        cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = action_name,
            variables = variables,
        )
    return [DefaultInfo()]

compile_without_module_maps = rule(
    implementation = _compile_without_module_maps_impl,
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
