# Copyright 2024 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Implementation of the `xcode_config` build rule."""

load("@build_bazel_apple_support//build_settings:build_settings.bzl", "read_possibly_native_flag")
load(
    "@build_bazel_apple_support//xcode/private:providers.bzl",
    "AvailableXcodesInfo",
    "XcodeVersionPropertiesInfo",
    "XcodeVersionRuleInfo",
)

visibility("public")

UNAVAILABLE_XCODE_MESSAGE = "'bazel fetch --configure' (Bzlmod) or 'bazel sync --configure' (WORKSPACE)"

def _xcode_config_impl(ctx):
    apple_fragment = ctx.fragments.apple
    cpp_fragment = ctx.fragments.cpp

    explicit_default_version = ctx.attr.default[XcodeVersionRuleInfo] if ctx.attr.default else None
    explicit_versions = [
        target[XcodeVersionRuleInfo]
        for target in ctx.attr.versions
    ] if ctx.attr.versions else []
    remote_versions = [
        target
        for target in ctx.attr.remote_versions[AvailableXcodesInfo].available_versions
    ] if ctx.attr.remote_versions else []
    local_versions = [
        target
        for target in ctx.attr.local_versions[AvailableXcodesInfo].available_versions
    ] if ctx.attr.local_versions else []

    local_default_version = ctx.attr.local_versions[AvailableXcodesInfo].default_version if ctx.attr.local_versions else None
    xcode_version_properties = None
    availability = "unknown"

    if _use_available_xcodes(
        explicit_default_version,
        explicit_versions,
        local_versions,
        remote_versions,
    ):
        xcode_version_properties, availability = _resolve_xcode_from_local_and_remote(
            ctx.actions,
            local_versions,
            remote_versions,
            read_possibly_native_flag(ctx, "xcode_version"),
            read_possibly_native_flag(ctx, "experimental_prefer_mutual_xcode"),
            local_default_version,
        )
    else:
        xcode_version_properties = _resolve_explicitly_defined_version(
            explicit_versions,
            explicit_default_version,
            read_possibly_native_flag(ctx, "xcode_version"),
        )
        availability = "UNKNOWN"

    ios_sdk_version = _dotted_version_or_default(xcode_version_properties.default_ios_sdk_version, "8.4")
    macos_sdk_version = _dotted_version_or_default(xcode_version_properties.default_macos_sdk_version, "10.11")
    tvos_sdk_version = _dotted_version_or_default(xcode_version_properties.default_tvos_sdk_version, "9.0")
    watchos_sdk_version = _dotted_version_or_default(xcode_version_properties.default_watchos_sdk_version, "2.0")
    visionos_sdk_version = _dotted_version_or_default(xcode_version_properties.default_visionos_sdk_version, "1.0")

    ios_minimum_os = read_possibly_native_flag(ctx, "ios_minimum_os") or ios_sdk_version
    macos_minimum_os = read_possibly_native_flag(ctx, "macos_minimum_os") or macos_sdk_version
    tvos_minimum_os = read_possibly_native_flag(ctx, "tvos_minimum_os") or tvos_sdk_version
    watchos_minimum_os = read_possibly_native_flag(ctx, "watchos_minimum_os") or watchos_sdk_version
    if cpp_fragment.minimum_os_version():
        visionos_minimum_os = apple_common.dotted_version(cpp_fragment.minimum_os_version())
    else:
        visionos_minimum_os = visionos_sdk_version

    # TODO: b/335817541 - At this time, there is still one place in the Bazel
    # Starlark built-in code that relies on this specific provider -- the code
    # in `objc/compilation_support.bzl` that registers the
    # `ObjcBinarySymbolStrip` action. Until that code is removed or updated, we
    # must make sure to always return this provider. However, we should also
    # return a newer, modernized provider, and have non-builtin Starlark clients
    # migrate to that provider ASAP.
    xcode_versions = apple_common.XcodeVersionConfig(
        ios_sdk_version = str(ios_sdk_version),
        ios_minimum_os_version = str(ios_minimum_os),
        visionos_sdk_version = str(visionos_sdk_version),
        visionos_minimum_os_version = str(visionos_minimum_os),
        watchos_sdk_version = str(watchos_sdk_version),
        watchos_minimum_os_version = str(watchos_minimum_os),
        tvos_sdk_version = str(tvos_sdk_version),
        tvos_minimum_os_version = str(tvos_minimum_os),
        macos_sdk_version = str(macos_sdk_version),
        macos_minimum_os_version = str(macos_minimum_os),
        xcode_version = xcode_version_properties.xcode_version,
        availability = availability,
        xcode_version_flag = apple_fragment.xcode_version_flag,
        include_xcode_execution_info = read_possibly_native_flag(ctx, "include_xcode_exec_requirements"),
    )

    providers = [
        DefaultInfo(runfiles = ctx.runfiles()),
        xcode_versions,
        xcode_version_properties,
    ]

    # TODO: b/367688113 - Once we've migrated all clients to generate and use
    # the new `xcode_sdk_variant` rules, fail if this field is not set.
    if xcode_version_properties.sdk_variant_info:
        providers.append(xcode_version_properties.sdk_variant_info)

    return providers

xcode_config = rule(
    attrs = {
        "default": attr.label(
            doc = """\
The default official version of Xcode to use.

The version specified by the provided `xcode_version` target is to be used if
no `xcode_version` build flag is specified. This is required if any `versions`
are set. This may not be set if `remote_versions` or `local_versions` is set.
""",
            providers = [[XcodeVersionRuleInfo]],
        ),
        "versions": attr.label_list(
            doc = """\
Accepted `xcode_version` targets that may be used.

If the value of the `xcode_version` build flag matches one of the aliases or
version number of any of the given `xcode_version` targets, the matching target
will be used. This may not be set if `remote_versions` or `local_versions` is
set.
""",
            providers = [[XcodeVersionRuleInfo]],
        ),
        "remote_versions": attr.label(
            doc = """\
The `xcode_version` targets that are available remotely.

These are used along with `local_versions` to select a mutually available
version. This may not be set if `versions` is set.
""",
            providers = [[AvailableXcodesInfo]],
        ),
        "local_versions": attr.label(
            doc = """\
The `xcode_version` targets that are available locally.

These are used along with `remote_versions` to select a mutually available
version. This may not be set if `versions` is set.
""",
            providers = [[AvailableXcodesInfo]],
        ),
        "_xcode_version": attr.label(
            default = "@build_bazel_apple_support//xcode:version",
        ),
        "_experimental_prefer_mutual_xcode": attr.label(
            default = "@build_bazel_apple_support//xcode:experimental_prefer_mutual_xcode",
        ),
        "_include_xcode_exec_requirements": attr.label(
            default = "@build_bazel_apple_support//xcode:include_xcode_exec_requirements",
        ),
        "_ios_minimum_os": attr.label(
            default = "@build_bazel_apple_support//xcode:ios_minimum_os",
        ),
        "_macos_minimum_os": attr.label(
            default = "@build_bazel_apple_support//xcode:macos_minimum_os",
        ),
        "_tvos_minimum_os": attr.label(
            default = "@build_bazel_apple_support//xcode:tvos_minimum_os",
        ),
        "_watchos_minimum_os": attr.label(
            default = "@build_bazel_apple_support//xcode:watchos_minimum_os",
        ),
    },
    doc = """\
A single target of this rule can be referenced by the `--xcode_version_config`
build flag to translate the `--xcode_version` flag into an accepted official
Xcode version. This allows selection of an official Xcode version from a number
of registered aliases.
""",
    fragments = ["apple", "cpp"],
    implementation = _xcode_config_impl,
)

def _use_available_xcodes(
        explicit_default_version,
        explicit_versions,
        local_versions,
        remote_versions):
    if remote_versions:
        if explicit_versions:
            fail("'versions' may not be set if '[local,remote]_versions' is set.")
        if explicit_default_version:
            fail("'default' may not be set if '[local,remote]_versions' is set.")
        if not local_versions:
            fail("if 'remote_versions' are set, you must also set 'local_versions'")
        return True
    return False

def _duplicate_alias_error(alias, versions):
    labels_containing_alias = []
    for version in versions:
        if alias in version.aliases or (version.xcode_version_properties.xcode_version == alias):
            labels_containing_alias.append(str(version.label))
    return "'{}' is registered to multiple labels ({}) in a single xcode_config rule".format(
        alias,
        ", ".join(labels_containing_alias),
    )

def _aliases_to_xcode_version(versions):
    version_map = {}
    if not versions:
        return version_map
    for version in versions:
        for alias in version.aliases:
            if alias in version_map:
                fail(_duplicate_alias_error(alias, versions))
            else:
                version_map[alias] = version
        version_string = version.xcode_version_properties.xcode_version
        if version_string not in version.aliases:  # only add the version if it's not also an alias
            if version_string in version_map:
                fail(_duplicate_alias_error(version_string, versions))
            else:
                version_map[version_string] = version
    return version_map

def _resolve_xcode_from_local_and_remote(
        actions,
        local_versions,
        remote_versions,
        xcode_version_flag,
        prefer_mutual_xcode,
        local_default_version):
    local_alias_to_version_map = _aliases_to_xcode_version(local_versions)
    remote_alias_to_version_map = _aliases_to_xcode_version(remote_versions)

    # A version is mutually available (available both locally and remotely) if the local version
    # attribute matches either the version attribute or one of the aliases of the remote version.
    # mutually_vailable_versions is a subset of remote_versions.
    # We assume the "version" attribute in local xcode_version contains a full version string,
    # e.g. including the build, while the versions in "alias" attribute may be less granular.
    # We don't make this assumption for remote xcode_versions.
    mutually_available_versions = {}
    for version in local_versions:
        version_string = version.xcode_version_properties.xcode_version
        if version_string in remote_alias_to_version_map:
            mutually_available_versions[version_string] = remote_alias_to_version_map[version_string]

    # We'd log an event here if we could!!
    if xcode_version_flag:
        remote_version_from_flag = remote_alias_to_version_map.get(xcode_version_flag)
        local_version_from_flag = local_alias_to_version_map.get(xcode_version_flag)
        availability = "BOTH"

        if remote_version_from_flag and local_version_from_flag:
            local_version_from_remote_versions = remote_alias_to_version_map.get(local_version_from_flag.xcode_version_properties.xcode_version)
            if local_version_from_remote_versions:
                return remote_version_from_flag.xcode_version_properties, availability
            else:
                fail(
                    ("Xcode version {0} was selected, either because --xcode_version was passed, or" +
                     " because xcode-select points to this version locally. This corresponds to" +
                     " local Xcode version {1}. That build of version {0} is not available" +
                     " remotely, but there is a different build of version {2}, which has" +
                     " version {2} and aliases {3}. You probably meant to use this version." +
                     " Please download it *and delete version {1}, then run `bazel shutdown`" +
                     " to continue using dynamic execution. If you really did intend to use" +
                     " local version {1}, please specify it fully with --xcode_version={1}.").format(
                        xcode_version_flag,
                        local_version_from_flag.xcode_version_properties.xcode_version,
                        remote_version_from_flag.xcode_version_properties.xcode_version,
                        remote_version_from_flag.aliases,
                    ),
                )

        elif local_version_from_flag:
            if mutually_available_versions:
                _warn(
                    actions,
                    "explicit_version_not_available_remotely_consider_mutual",
                    version = xcode_version_flag,
                    mutual_versions = [version for version in mutually_available_versions],
                )
            else:
                _warn(
                    actions,
                    "explicit_version_not_available_remotely",
                    version = xcode_version_flag,
                )
            return local_version_from_flag.xcode_version_properties, "LOCAL"

        elif remote_version_from_flag:
            _warn(
                actions,
                "version_not_available_locally",
                version = xcode_version_flag,
                command = UNAVAILABLE_XCODE_MESSAGE,
                local_versions = ", ".join([version for version in local_alias_to_version_map.keys()]),
            )
            availability = "REMOTE"

            return remote_version_from_flag.xcode_version_properties, availability

        else:  # fail if we can't find any version to match
            fail(
                ("--xcode_version={0} specified, but '{0}' is not an available Xcode version." +
                 " Locally available versions: [{2}]. Remotely available versions: [{3}]. If" +
                 " you believe you have '{0}' installed, try running {1}, and then" +
                 " re-run your command.").format(
                    xcode_version_flag,
                    UNAVAILABLE_XCODE_MESSAGE,
                    ", ".join([version.xcode_version_properties.xcode_version for version in local_versions]),
                    ", ".join([version.xcode_version_properties.xcode_version for version in remote_versions]),
                ),
            )

    # --xcode_version is not set
    availability = "UNKNOWN"
    local_version = None

    # If there aren't any mutually available versions, select the local default.
    if not mutually_available_versions:
        _warn(
            actions,
            "local_default_not_available_remotely",
            local_version = local_default_version.xcode_version_properties.xcode_version,
            remote_versions = ", ".join([version.xcode_version_properties.xcode_version for version in remote_versions]),
        )
        local_version = local_default_version
        availability = "LOCAL"
    elif (local_default_version.xcode_version_properties.xcode_version in remote_alias_to_version_map):
        #  If the local default version is also available remotely, use it.
        availability = "BOTH"
        local_version = remote_alias_to_version_map.get(local_default_version.xcode_version_properties.xcode_version)
    else:
        # If an alias of the local default version is available remotely, use it.
        for version_number in local_default_version.aliases:
            if version_number in remote_alias_to_version_map:
                availability = "BOTH"
                local_version = remote_alias_to_version_map.get(version_number)
                break

    if local_version:
        return local_version.xcode_version_properties, availability

    # The local default is not available remotely.
    if prefer_mutual_xcode:
        # If we prefer a mutually available version, the newest one.
        newest_version = "0.0"
        default_version = None
        for _, version in mutually_available_versions.items():
            if _compare_version_strings(version.xcode_version_properties.xcode_version, newest_version) > 0:
                default_version = version
                newest_version = default_version.xcode_version_properties.xcode_version

        return default_version.xcode_version_properties, "BOTH"
    else:
        # Use the local default
        return local_default_version.xcode_version_properties, "LOCAL"

def _compare_version_strings(first, second):
    return apple_common.dotted_version(first).compare_to(
        apple_common.dotted_version(second),
    )

def _resolve_explicitly_defined_version(
        explicit_versions,
        explicit_default_version,
        xcode_version_flag):
    if explicit_default_version and explicit_default_version.label not in [
        version.label
        for version in explicit_versions
    ]:
        fail(
            "default label '{}' must be contained in versions attribute".format(
                explicit_default_version.label,
            ),
        )
    if not explicit_versions:
        if explicit_default_version:
            fail("default label must be contained in versions attribute")
        return XcodeVersionPropertiesInfo(xcode_version = None)

    if not explicit_default_version:
        fail("if any versions are specified, a default version must be specified")

    alias_to_versions = _aliases_to_xcode_version(explicit_versions)
    if xcode_version_flag:
        flag_version = alias_to_versions.get(str(xcode_version_flag))
        if flag_version:
            return flag_version.xcode_version_properties
        else:
            fail(
                ("--xcode_version={0} specified, but '{0}' is not an available Xcode version. " +
                 "If you believe you have '{0}' installed, try running \"bazel shutdown\", and then " +
                 "re-run your command.").format(xcode_version_flag),
            )
    return alias_to_versions.get(explicit_default_version.xcode_version_properties.xcode_version).xcode_version_properties

def _dotted_version_or_default(field, default):
    return apple_common.dotted_version(field) or default

_WARNINGS = {
    "version_not_available_locally": """\
--xcode_version={version} specified, but it is not available locally. \
Your build will fail if any actions require a local Xcode. \
If you believe you have '{version}' installed, try running {command}, \
and then re-run your command. Locally available versions: {local_versions}.
""",
    "local_default_not_available_remotely": """\
Using a local Xcode version, '{local_version}', since there are no \
remotely available Xcodes on this machine. Consider downloading one of the \
remotely available Xcode versions ({remote_versions}) in order to get the best \
build performance.
""",
    "explicit_version_not_available_remotely": """\
--xcode_version={version} specified, but it is not available remotely. Actions \
requiring Xcode will be run locally, which could make your build slower.
""",
    "explicit_version_not_available_remotely_consider_mutual": """\
--xcode_version={version} specified, but it is not available remotely. Actions \
requiring Xcode will be run locally, which could make your build slower. \
Consider using one of [{mutual_versions}].
""",
}

def _warn(actions, msg_id, **kwargs):
    """Print a warning and also record it as a testable dummy action.

    Starlark doesn't support testing the output of the `print()` function, so
    this function also registers a dummy action with a specifically formatted
    mnemonic that can be read in the test using the `assert_warning` helper.

    Args:
        actions: The object used to register actions.
        msg_id: A string identifying the warning as a key in the `_WARNINGS`
            dictionary.
        **kwargs: Formatting arguments for the message string.
    """

    # buildifier: disable=print
    print(_WARNINGS[msg_id].format(**kwargs))

    mnemonic = "Warning:{}".format(msg_id)
    if kwargs:
        # Sort the format arguments by key so that they're deterministically
        # ordered for tests.
        sorted_values = []
        for key in sorted(kwargs.keys()):
            sorted_values.append("{}={}".format(key, str(kwargs[key])))
        mnemonic += ":{}".format(";".join(sorted_values))

    actions.do_nothing(
        mnemonic = mnemonic,
    )
