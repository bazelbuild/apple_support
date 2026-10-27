"""Rules for fetching dynamic info to insert into the toolchain.

Since the rules based toolchains operate as normal targets, some of the
internal bazel APIs that we use to derive some flags must be exposed via custom
rules.
"""

load("@rules_cc//cc/toolchains:providers.bzl", "ExecutionRequirementsInfo")
load("//lib:apple_support.bzl", "apple_support")

def _sdk_version_for_platform(xcode_config, platform_type):
    if platform_type == apple_common.platform_type.ios:
        return xcode_config.sdk_version_for_platform(apple_common.platform.ios_device)
    elif platform_type == apple_common.platform_type.tvos:
        return xcode_config.sdk_version_for_platform(apple_common.platform.tvos_device)
    elif platform_type == apple_common.platform_type.visionos:
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
    elif platform_type == apple_common.platform_type.visionos and is_simulator:
        return "XRSimulator"
    elif platform_type == apple_common.platform_type.visionos:
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

def _numeric_version(version):
    """Returns the leading numeric components of a version, e.g. "1.2.foo" -> "1.2"."""
    parts = []
    for part in str(version).split("."):
        if not part.isdigit():
            break
        parts.append(part)
    return ".".join(parts)

def _dynamic_toolchain_info_impl(ctx):
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
        platform_type = apple_common.platform_type.visionos
    elif ctx.target_platform_has_constraint(ctx.attr._linux[platform_common.ConstraintValueInfo]):
        return [platform_common.TemplateVariableInfo({"ARCH": triple_arch})]
    else:
        fail("Unknown OS in target platform")

    apple_platform_info = apple_support.platform_info_from_rule_ctx(ctx)

    is_simulator = ctx.target_platform_has_constraint(ctx.attr._simulator[platform_common.ConstraintValueInfo])
    if is_simulator:
        triple_suffix = "-simulator"
    else:
        triple_suffix = ""

    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    sdk_version = _sdk_version_for_platform(xcode_config, platform_type)

    # Clang cannot parse non-numeric version suffixes in a target triple and
    # silently falls back to a very old deployment target, so only the numeric
    # part of the version goes into the triple.
    target_os_version = _numeric_version(xcode_config.minimum_os_for_platform_type(platform_type))

    # Any suffix following the numeric part of the SDK version is carried over
    # to the SDK platform name.
    sdk_name = _sdk_name(platform_type, is_simulator) + str(sdk_version)[len(_numeric_version(sdk_version)):]

    target = "{}-apple-{}{}{}".format(
        triple_arch,
        triple_os,
        target_os_version,
        triple_suffix,
    )

    xcode_env = {
        "APPLE_SDK_PLATFORM": "INVALID",
        "APPLE_SDK_VERSION_OVERRIDE": "INVALID",
        "XCODE_VERSION_OVERRIDE": "INVALID",
    }
    if xcode_config.xcode_version():
        xcode_env = {
            "APPLE_SDK_PLATFORM": sdk_name,
            "APPLE_SDK_VERSION_OVERRIDE": str(sdk_version),  # TODO: Remove once we drop bazel 7.x support
            "XCODE_VERSION_OVERRIDE": str(xcode_config.xcode_version()),
        }

    return [platform_common.TemplateVariableInfo(
        xcode_env | {
            "ARCH": triple_arch,
            "PLATFORM_FRAMEWORKS": apple_support.path_placeholders.platform_frameworks(apple_platform_info = apple_platform_info),
            "TARGET": target,
        },
    )]

dynamic_toolchain_info = rule(
    implementation = _dynamic_toolchain_info_impl,
    attrs = apple_support.platform_constraint_attrs() | {
        "_linux": attr.label(default = "@platforms//os:linux"),
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
        "_simulator": attr.label(default = "@apple_support//constraints:simulator"),
        "_xcode_config": attr.label(default = configuration_field(
            fragment = "apple",
            name = "xcode_config_label",
        )),
    },
    fragments = [
        "apple",
    ],
)

def _xcode_execution_info_impl(ctx):
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    return [
        ExecutionRequirementsInfo(
            label = ctx.label,
            requirements = tuple(xcode_config.execution_info().keys()),
        ),
    ]

xcode_execution_info = rule(
    implementation = _xcode_execution_info_impl,
    attrs = apple_support.action_required_attrs(),
)
