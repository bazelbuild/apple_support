def _sdk_version_for_platform(xcode_config, platform_type):
    if platform_type == apple_common.platform_type.ios:
        return xcode_config.sdk_version_for_platform(apple_common.platform.ios_device)
    elif platform_type == apple_common.platform_type.tvos:
        return xcode_config.sdk_version_for_platform(apple_common.platform.tvos_device)
    elif platform_type == getattr(apple_common.platform_type, "visionos", None):
        return xcode_config.sdk_version_for_platform(apple_common.platform.visionos_device)
    elif platform_type == apple_common.platform_type.watchos:
        return xcode_config.sdk_version_for_platform(apple_common.platform.watchos_device)
    elif platform_type == apple_common.platform_type.macos:
        return xcode_config.sdk_version_for_platform(apple_common.platform.macos)
    else:
        fail("Unhandled platform type: {}".format(platform_type))

def _sdk_name(platform_type, is_simulator):
    if platform_type == apple_common.platform_type.ios and is_simulator:
        return "iPhoneSimulator"
    elif platform_type == apple_common.platform_type.ios:
        return "iPhoneOS"
    elif platform_type == getattr(apple_common.platform_type, "visionos", None) and is_simulator:
        return "XRSimulator"
    elif platform_type == getattr(apple_common.platform_type, "visionos", None):
        return "XROS"
    elif platform_type == apple_common.platform_type.watchos and is_simulator:
        return "WatchSimulator"
    elif platform_type == apple_common.platform_type.watchos:
        return "WatchOS"
    elif platform_type == apple_common.platform_type.tvos and is_simulator:
        return "AppleTVSimulator"
    elif platform_type == apple_common.platform_type.tvos:
        return "AppleTVOS"
    elif platform_type == apple_common.platform_type.macos:
        return "MacOSX"
    else:
        fail("Unhandled platform type: {}".format(platform_type))

# def _foo_impl(ctx):
#     xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]

#     # xcode_execution_requirements = xcode_config.execution_info().keys() # FIXME
#     target_os_version = xcode_config.minimum_os_for_platform_type(ctx.attr.platform_type)
#     sdk_version = _sdk_version_for_platform(xcode_config, ctx.attr.platform_type)

#     return platform_common.TemplateVariableInfo({
#         "TARGET": "thing",
#     })

def _foo_impl(ctx):
    if ctx.target_platform_has_constraint(ctx.attr._macos[platform_common.ConstraintValueInfo]):
        triple_os = "macosx"
        platform_type = apple_common.platform_type.macos
    elif ctx.target_platform_has_constraint(ctx.attr._ios[platform_common.ConstraintValueInfo]):
        triple_os = "ios"
        platform_type = apple_common.platform_type.ios
    elif ctx.target_platform_has_constraint(ctx.attr._tvos[platform_common.ConstraintValueInfo]):
        triple_os = "tvos"
        platform_type = apple_common.platform_type.tvos
    elif ctx.target_platform_has_constraint(ctx.attr._watchos[platform_common.ConstraintValueInfo]):
        triple_os = "watchos"
        platform_type = apple_common.platform_type.watchos
    elif ctx.target_platform_has_constraint(ctx.attr._visionos[platform_common.ConstraintValueInfo]):
        triple_os = "xros"
        platform_type = getattr(apple_common.platform_type, "visionos", None)
    else:
        fail("Unknown OS in target platform")

    if ctx.target_platform_has_constraint(ctx.attr._arm64[platform_common.ConstraintValueInfo]):
        triple_arch = "arm64"
    elif ctx.target_platform_has_constraint(ctx.attr._arm64e[platform_common.ConstraintValueInfo]):
        triple_arch = "arm64e"
    elif ctx.target_platform_has_constraint(ctx.attr._x86_64[platform_common.ConstraintValueInfo]):
        triple_arch = "x86_64"
    elif ctx.target_platform_has_constraint(ctx.attr._arm64_32[platform_common.ConstraintValueInfo]):
        triple_arch = "arm64_32"
    elif ctx.target_platform_has_constraint(ctx.attr._armv7k[platform_common.ConstraintValueInfo]):
        triple_arch = "armv7k"
    else:
        fail("Unknown CPU in target platform")

    is_simulator = ctx.target_platform_has_constraint(ctx.attr._simulator[platform_common.ConstraintValueInfo])
    if is_simulator:
        triple_suffix = "-simulator"
    else:
        triple_suffix = ""

    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]

    # xcode_execution_requirements = xcode_config.execution_info().keys() # FIXME
    target_os_version = xcode_config.minimum_os_for_platform_type(platform_type)
    sdk_version = _sdk_version_for_platform(xcode_config, platform_type)

    target = "{}-apple-{}{}{}{}".format(
        triple_arch,
        triple_os,
        ctx.attr.target_triple_version,
        triple_suffix,
        target_os_version,
    )

    xcode_env = {
        "APPLE_SDK_PLATFORM": "INVALID",
        "APPLE_SDK_VERSION_OVERRIDE": "INVALID",
        "XCODE_VERSION_OVERRIDE": "INVALID",
    }
    if xcode_config.xcode_version():
        xcode_env = {
            "APPLE_SDK_PLATFORM": _sdk_name(platform_type, is_simulator),
            "APPLE_SDK_VERSION_OVERRIDE": str(sdk_version),  # TODO: Remove once we drop bazel 7.x support
            "XCODE_VERSION_OVERRIDE": str(xcode_config.xcode_version()),
        }

    return [platform_common.TemplateVariableInfo(
        xcode_env | {
            "TARGET": target,
        },
    )]

foo = rule(
    implementation = _foo_impl,
    attrs = {
        "target_triple_version": attr.string(),
        "_macos": attr.label(default = "@platforms//os:macos"),
        "_ios": attr.label(default = "@platforms//os:ios"),
        "_tvos": attr.label(default = "@platforms//os:tvos"),
        "_watchos": attr.label(default = "@platforms//os:watchos"),
        "_visionos": attr.label(default = "@platforms//os:visionos"),
        "_arm64": attr.label(default = "@platforms//cpu:arm64"),
        "_arm64e": attr.label(default = "@platforms//cpu:arm64e"),
        "_x86_64": attr.label(default = "@platforms//cpu:x86_64"),
        "_arm64_32": attr.label(default = "@platforms//cpu:arm64_32"),
        "_armv7k": attr.label(default = "@platforms//cpu:armv7k"),
        "_simulator": attr.label(default = "@build_bazel_apple_support//constraints:simulator"),
        "_xcode_config": attr.label(default = configuration_field(
            fragment = "apple",
            name = "xcode_config_label",
        )),
    },
)

# foo = rule(
#     implementation = _foo_impl,
#     attrs = {
#         "platform_type": attr.string(),
#         "_xcode_config": attr.label(default = configuration_field(
#             fragment = "apple",
#             name = "xcode_config_label",
#         )),
#     },
#     fragments = [
#         "apple",
#         "cpp",
#     ],
# )
