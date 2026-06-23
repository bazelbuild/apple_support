# Copyright 2018 The Bazel Authors. All rights reserved.
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
"""Definitions for registering actions on Apple platforms."""

load("@bazel_skylib//lib:types.bzl", "types")
load(
    "@build_bazel_apple_support//lib:missing_platform_fallback_users.bzl",
    "ALLOWED_USERS_OF_MISSING_PLATFORM_FALLBACK",
)
load(
    "@build_bazel_apple_support//lib/private:providers.bzl",
    "new_appleplatforminfo",
)

visibility("public")

# Options to declare the level of Xcode path resolving needed in an `apple_support.run()`
# invocation.
_XCODE_PATH_RESOLVE_LEVEL = struct(
    none = None,
    args = "args",
    args_and_files = "args_and_files",
)

_XCODE_PROCESSOR__ARGS = r"""#!/bin/bash

set -eu

# SYNOPSIS
#   Rewrites any Bazel placeholder strings in the given argument string,
#   echoing the result.
#
# USAGE
#   rewrite_argument <argument>
function rewrite_argument {
  ARG="$1"
  ARG="${ARG//__BAZEL_XCODE_DEVELOPER_DIR__/$DEVELOPER_DIR}"
  ARG="${ARG//__BAZEL_XCODE_SDKROOT__/$SDKROOT}"
  echo "$ARG"
}

TOOLNAME="$1"
shift

ARGS=()

for ARG in "$@" ; do
  ARGS+=("$(rewrite_argument "$ARG")")
done

exec "$TOOLNAME" "${ARGS[@]}"
"""

_XCODE_PROCESSOR__ARGS_AND_FILES = r"""#!/bin/bash

set -eu

# SYNOPSIS
#   Rewrites any Bazel placeholder strings in the given argument string,
#   echoing the result.
#
# USAGE
#   rewrite_argument <argument>
function rewrite_argument {
  ARG="$1"
  ARG="${ARG//__BAZEL_XCODE_DEVELOPER_DIR__/$DEVELOPER_DIR}"
  ARG="${ARG//__BAZEL_XCODE_SDKROOT__/$SDKROOT}"
  echo "$ARG"
}

# SYNOPSIS
#   Rewrites any Bazel placeholder strings in the given params file, if any.
#   If there were no substitutions to be made, the original path is echoed back
#   out; otherwise, this function echoes the path to a temporary file
#   containing the rewritten file.
#
# USAGE
#   rewrite_params_file <path>
function rewrite_params_file {
  PARAMSFILE="$1"
  if grep -qe '__BAZEL_XCODE_\(DEVELOPER_DIR\|SDKROOT\)__' "$PARAMSFILE" ; then
    NEWFILE="$(mktemp "${TMPDIR%/}/bazel_xcode_wrapper_params.XXXXXXXXXX")"
    sed \
        -e "s#__BAZEL_XCODE_DEVELOPER_DIR__#$DEVELOPER_DIR#g" \
        -e "s#__BAZEL_XCODE_SDKROOT__#$SDKROOT#g" \
        "$PARAMSFILE" > "$NEWFILE"
    echo "$NEWFILE"
  else
    # There were no placeholders to substitute, so just return the original
    # file.
    echo "$PARAMSFILE"
  fi
}

TOOLNAME="$1"
shift

ARGS=()

# If any temporary files are created (like rewritten response files), clean
# them up when the script exits.
TEMPFILES=()
trap '[[ ${#TEMPFILES[@]} -ne 0 ]] && rm "${TEMPFILES[@]}"' EXIT

for ARG in "$@" ; do
  case "$ARG" in
  @*)
    PARAMSFILE="${ARG:1}"
    NEWFILE=$(rewrite_params_file "$PARAMSFILE")
    if [[ "$PARAMSFILE" != "$NEWFILE" ]] ; then
      TEMPFILES+=("$NEWFILE")
    fi
    ARG="@$NEWFILE"
    ;;
  *)
    ARG=$(rewrite_argument "$ARG")
    ;;
  esac
  ARGS+=("$ARG")
done

# We can't use `exec` here because we need to make sure the `trap` runs
# afterward.
"$TOOLNAME" "${ARGS[@]}"
"""

def _platform_frameworks_path_placeholder(
        *,
        apple_platform_info = None,
        apple_fragment = None):
    """Returns the platform's frameworks directory, anchored to the Xcode path placeholder.

    Args:
        apple_platform_info: An ApplePlatformInfo provider.
            Typically from `apple_support.platform_info_from_rule_ctx(ctx)`.
        apple_fragment: A reference to the apple fragment. Typically from `ctx.fragments.apple`.
            Deprecated: Use apple_platform_info instead.

    Returns:
        Returns a string with the platform's frameworks directory, anchored to the Xcode path
        placeholder.
    """
    if apple_platform_info:
        platform_name = apple_platform_info.platform.name_in_plist
    elif apple_fragment:
        platform_name = apple_fragment.single_arch_platform.name_in_plist
    else:
        fail("Either apple_platform_info or apple_fragment must be provided.")

    return "{xcode_path}/Platforms/{platform_name}.platform/Developer/Library/Frameworks".format(
        platform_name = platform_name,
        xcode_path = _xcode_path_placeholder(),
    )

def _sdkroot_path_placeholder():
    """Returns a placeholder value to be replaced with SDKROOT during action execution.

    In order to get this values replaced, you'll need to use the `apple_support.run()` API by
    setting the `xcode_path_resolve_level` argument to either the
    `apple_support.xcode_path_resolve_level.args` or
    `apple_support.xcode_path_resolve_level.args_and_files` value.

    Returns:
        Returns a placeholder value to be replaced with SDKROOT during action execution.
    """
    return "__BAZEL_XCODE_SDKROOT__"

def _xcode_path_placeholder():
    """Returns a placeholder value to be replaced with DEVELOPER_DIR during action execution.

    In order to get this values replaced, you'll need to use the `apple_support.run()` API by
    setting the `xcode_path_resolve_level` argument to either the
    `apple_support.xcode_path_resolve_level.args` or
    `apple_support.xcode_path_resolve_level.args_and_files` value.

    Returns:
        Returns a placeholder value to be replaced with DEVELOPER_DIR during action execution.
    """
    return "__BAZEL_XCODE_DEVELOPER_DIR__"

def _kwargs_for_apple_platform(
        *,
        xcode_config,
        apple_platform_info = None,
        apple_fragment = None,
        **kwargs):
    """Returns a modified dictionary with required arguments to run on Apple platforms."""
    processed_args = dict(kwargs)

    if apple_platform_info:
        platform = apple_platform_info.platform
    elif apple_fragment:
        platform = apple_fragment.single_arch_platform
    else:
        fail("Either apple_platform_info or apple_fragment must be provided.")

    merged_env = {}
    original_env = processed_args.get("env")
    if original_env:
        merged_env.update(original_env)

    # Add the environment variables required for DEVELOPER_DIR and SDKROOT last to avoid clients
    # overriding these values.
    merged_env.update(apple_common.apple_host_system_env(xcode_config))
    merged_env.update(
        apple_common.target_apple_env(xcode_config, platform),
    )

    merged_execution_requirements = {}
    original_execution_requirements = processed_args.get("execution_requirements")
    if original_execution_requirements:
        merged_execution_requirements.update(original_execution_requirements)

    # Add the Xcode execution requirements last to avoid clients overriding these values.
    merged_execution_requirements.update(xcode_config.execution_info())

    processed_args["env"] = merged_env
    processed_args["execution_requirements"] = merged_execution_requirements
    return processed_args

def _action_required_attrs():
    """Returns a dictionary with required attributes for registering actions on Apple platforms.

    This method adds private attributes which should not be used outside of the apple_support
    codebase. It also adds the following attributes which are considered to be public for rule
    maintainers to use:

     * `_xcode_config`: Attribute that references a target containing the single
       `apple_common.XcodeVersionConfig` provider. This provider can be used to inspect Xcode-related
       properties about the Xcode being used for the build, as specified with the `--xcode_version`
       Bazel flag. The most common way to retrieve this provider is:
       `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.

    The returned `dict` can be added to the rule's attributes using Skylib's `dicts.add()` method.

    Returns:
        A `dict` object containing attributes to be added to rule implementations.
    """
    return {
        "_xcode_config": attr.label(
            default = "@build_bazel_apple_support//xcode:version_config",
        ),
    }

def _platform_constraint_attrs():
    """Returns a dictionary of all known Apple platform constraints that can be resolved.

    The returned `dict` can be added to the rule's attributes using Skylib's `dicts.add()` method.

    Returns:
        A `dict` object containing attributes to be added to rule implementations.
    """
    return {
        "_ios_constraint": attr.label(
            default = Label("@platforms//os:ios"),
        ),
        "_macos_constraint": attr.label(
            default = Label("@platforms//os:macos"),
        ),
        "_tvos_constraint": attr.label(
            default = Label("@platforms//os:tvos"),
        ),
        "_visionos_constraint": attr.label(
            default = Label("@platforms//os:visionos"),
        ),
        "_watchos_constraint": attr.label(
            default = Label("@platforms//os:watchos"),
        ),
        "_arm64_constraint": attr.label(
            default = Label("@platforms//cpu:arm64"),
        ),
        "_arm64e_constraint": attr.label(
            default = Label("@platforms//cpu:arm64e"),
        ),
        "_arm64_32_constraint": attr.label(
            default = Label("@platforms//cpu:arm64_32"),
        ),
        "_armv7k_constraint": attr.label(
            default = Label("@platforms//cpu:armv7k"),
        ),
        "_x86_64_constraint": attr.label(
            default = Label("@platforms//cpu:x86_64"),
        ),
        "_pointer_authentication_constraint": attr.label(
            default = Label("@build_bazel_apple_support//constraints:pointer_authentication"),
        ),
        "_apple_device_constraint": attr.label(
            default = Label("@build_bazel_apple_support//constraints:device"),
        ),
        "_apple_simulator_constraint": attr.label(
            default = Label("@build_bazel_apple_support//constraints:simulator"),
        ),
    }

def _run(
        *,
        actions,
        xcode_config,
        apple_platform_info = None,
        apple_fragment = None,
        xcode_path_resolve_level = _XCODE_PATH_RESOLVE_LEVEL.none,
        **kwargs):
    """Registers an action to run on an Apple machine.

    In order to use `apple_support.run()`, you'll need to modify your rule definition to add the
    following:

      * `fragments = ["apple"]`
      * Add the `apple_support.action_required_attrs()` attributes to the `attrs` dictionary. This
        can be done using the `dicts.add()` method from Skylib.

    This method registers an action to run on an Apple machine, configuring it to ensure that the
    `DEVELOPER_DIR` and `SDKROOT` environment variables are set.

    If the `xcode_path_resolve_level` is enabled, this method will replace the given `executable`
    with a wrapper script that will replace all instances of the `__BAZEL_XCODE_DEVELOPER_DIR__` and
    `__BAZEL_XCODE_SDKROOT__` placeholders in the given arguments with the values of `DEVELOPER_DIR`
    and `SDKROOT`, respectively.

    In your rule implementation, you can use references to Xcode through the
    `apple_support.path_placeholders` API, which in turn uses the placeholder values as described
    above. The available APIs are:

      * `apple_support.path_placeholders.xcode()`: Returns a reference to the Xcode.app
        installation path.
      * `apple_support.path_placeholders.sdkroot()`: Returns a reference to the SDK root path.
      * `apple_support.path_placeholders.platform_frameworks(ctx)`: Returns the Frameworks path
        within the Xcode installation, for the requested platform.

    If the `xcode_path_resolve_level` value is:

      * `apple_support.xcode_path_resolve_level.none`: No processing will be done to the given
        `arguments`.
      * `apple_support.xcode_path_resolve_level.args`: Only instances of the placeholders in the
         argument strings will be replaced.
      * `apple_support.xcode_path_resolve_level.args_and_files`: Instances of the placeholders in
         the arguments strings and instances of the placeholders within response files (i.e. any
         path argument beginning with `@`) will be replaced.

    Args:
        actions: The actions provider from ctx.actions.
        xcode_config: The xcode_config as found in the current rule or aspect's
            context. Typically from `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.
        apple_platform_info: An ApplePlatformInfo provider.
        apple_fragment: A reference to the apple fragment. Typically from `ctx.fragments.apple`.
            Deprecated: Use apple_platform_info instead.
        xcode_path_resolve_level: The level of Xcode path replacement required for the action.
        **kwargs: See `ctx.actions.run` for the rest of the available arguments.
    """

    if xcode_path_resolve_level == _XCODE_PATH_RESOLVE_LEVEL.none:
        actions.run(**_kwargs_for_apple_platform(
            xcode_config = xcode_config,
            apple_platform_info = apple_platform_info,
            apple_fragment = apple_fragment,
            **kwargs
        ))
        return

    # Since a label/name isn't passed in, use the first output to derive a name
    # that will hopefully be unique.
    output0 = kwargs.get("outputs")[0]
    if xcode_path_resolve_level == _XCODE_PATH_RESOLVE_LEVEL.args:
        script = _XCODE_PROCESSOR__ARGS
        suffix = "args"
    else:
        script = _XCODE_PROCESSOR__ARGS_AND_FILES
        suffix = "args_and_files"
    processor_script = actions.declare_file("{}_{}_processor_script_{}.sh".format(
        output0.basename,
        hash(output0.short_path),
        suffix,
    ))
    actions.write(processor_script, script, is_executable = True)

    processed_kwargs = _kwargs_for_apple_platform(
        xcode_config = xcode_config,
        apple_platform_info = apple_platform_info,
        apple_fragment = apple_fragment,
        **kwargs
    )

    all_arguments = []

    # If the client requires Xcode path resolving, push the original executable to be the first
    # argument, as the executable will be set to be the xcode_path_wrapper script.
    # Note: Bounce through an actions.args() incase the executable was a `File`, this allows it
    # to then work within the arguments list.
    executable_args = actions.args()
    original_executable = processed_kwargs.pop("executable")

    # actions.run supports multiple executable types. (File; or string; or FilesToRunProvider)
    # If the passed in executable is a FilesToRunProvider, only add the main executable to the
    # should be added to the executable args.
    if type(original_executable) == "FilesToRunProvider":
        executable_args.add(original_executable.executable)
    else:
        executable_args.add(original_executable)
    all_arguments.append(executable_args)

    # Append the original arguments to the full list of arguments, after the original executable.
    original_args_list = processed_kwargs.pop("arguments", [])
    if not original_args_list:
        fail("Error: Does not make sense to request args processing without any `arguments`.")
    all_arguments.extend(original_args_list)

    # We also need to include the user executable in the "tools" argument of the action, since it
    # won't be referenced by "executable" anymore.
    original_tools = processed_kwargs.pop("tools", None)
    if types.is_list(original_tools):
        all_tools = [original_executable] + original_tools
    elif types.is_depset(original_tools):
        all_tools = depset([original_executable], transitive = [original_tools])
    elif original_tools:
        fail("'tools' argument must be a sequence or depset.")
    elif not types.is_string(original_executable):
        # Only add the user_executable to the "tools" list if it's a File, not a string.
        all_tools = [original_executable]
    else:
        all_tools = []

    actions.run(
        executable = processor_script,
        arguments = all_arguments,
        tools = all_tools,
        **processed_kwargs
    )

def _run_shell(
        *,
        actions,
        xcode_config,
        apple_platform_info = None,
        apple_fragment = None,
        **kwargs):
    """Registers a shell action to run on an Apple machine.

    In order to use `apple_support.run_shell()`, you'll need to modify your rule definition to add
    the following:

      * `fragments = ["apple"]`
      * Add the `apple_support.action_required_attrs()` attributes to the `attrs` dictionary. This
        can be done using the `dicts.add()` method from Skylib.

    This method registers an action to run on an Apple machine, configuring it to ensure that the
    `DEVELOPER_DIR` and `SDKROOT` environment variables are set.

    `run_shell` does not support placeholder substitution. To achieve placeholder substitution,
    please use `run` instead.

    Args:
        actions: The actions provider from ctx.actions.
        xcode_config: The xcode_config as found in the current rule or aspect's
            context. Typically from `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.
        apple_platform_info: An ApplePlatformInfo provider.
        apple_fragment: A reference to the apple fragment. Typically from `ctx.fragments.apple`.
            Deprecated: Use apple_platform_info instead.
        **kwargs: See `ctx.actions.run_shell` for the rest of the available arguments.
    """

    # TODO(b/77637734) remove "workaround" once the bazel issue is resolved.
    # Bazel doesn't always get the shell right for a single string `commands`;
    # so work around that case by faking it as a list of strings that forces
    # the shell correctly. Skip all this if there are arguments as hopefully
    # that will work, if it doesn't see the mentioned bug.
    command = kwargs.get("command")
    if command and types.is_string(command) and not kwargs.get("arguments", []):
        processed_args = dict(kwargs)
        processed_args["command"] = ["/bin/sh", "-c", command]
        kwargs = processed_args

    actions.run_shell(**_kwargs_for_apple_platform(
        xcode_config = xcode_config,
        apple_platform_info = apple_platform_info,
        apple_fragment = apple_fragment,
        **kwargs
    ))

def _target_arch_from_rule_ctx(
        ctx,
        *,
        fail_on_missing_constraint = True):
    """Returns a `String` representing the target architecture based on constraints.

    The returned `String` will represent a cpu architecture, such as `arm64` or `arm64e`.

    In order to use `apple_support.target_arch_from_rule_ctx()`, you'll need to modify your rule
    definition to add the following:

      * Add the `apple_support.platform_constraint_attrs()` attributes to the `attrs` dictionary.
        This can be done using the `dicts.add()` method from Skylib.

    Args:
        ctx: The context of the rule that has Apple platform constraint attributes.
        fail_on_missing_constraint: Whether to fail if no constraint is found. (default: `True`)

    Returns:
        A `String` representing the selected target architecture or cpu type (e.g. `arm64`,
        `arm64e`) or `None` if no constraint is found.
    """
    arm64_constraint = ctx.attr._arm64_constraint[platform_common.ConstraintValueInfo]
    arm64e_constraint = ctx.attr._arm64e_constraint[platform_common.ConstraintValueInfo]
    arm64_32_constraint = ctx.attr._arm64_32_constraint[platform_common.ConstraintValueInfo]
    armv7k_constraint = ctx.attr._armv7k_constraint[platform_common.ConstraintValueInfo]
    x86_64_constraint = ctx.attr._x86_64_constraint[platform_common.ConstraintValueInfo]

    pointer_authentication_constraint = (
        ctx.attr._pointer_authentication_constraint[platform_common.ConstraintValueInfo]
    )

    if ctx.target_platform_has_constraint(arm64_constraint):
        if ctx.target_platform_has_constraint(pointer_authentication_constraint):
            return "arm64e"
        else:
            return "arm64"
    elif ctx.target_platform_has_constraint(arm64e_constraint):
        return "arm64e"
    elif ctx.target_platform_has_constraint(arm64_32_constraint):
        return "arm64_32"
    elif ctx.target_platform_has_constraint(armv7k_constraint):
        return "armv7k"
    elif ctx.target_platform_has_constraint(x86_64_constraint):
        return "x86_64"
    if not fail_on_missing_constraint:
        return None
    fail("ERROR: A valid Apple cpu constraint could not be found from the resolved toolchain.")

def _target_environment_from_rule_ctx(
        ctx,
        *,
        fail_on_missing_constraint = True):
    """Returns a `String` representing the target environment based on constraints.

    The returned `String` will represent an environment, such as `device` or `simulator`.

    For consistency with other Apple platforms, `macos` is considered to be a `device`.

    In order to use `apple_support.target_environment_from_rule_ctx()`, you'll need to modify your
    rule definition to add the following:

      * Add the `apple_support.platform_constraint_attrs()` attributes to the `attrs` dictionary.
        This can be done using the `dicts.add()` method from Skylib.

    Args:
        ctx: The context of the rule that has Apple platform constraint attributes.
        fail_on_missing_constraint: Whether to fail if no constraint is found. (default: `True`)

    Returns:
        A `String` representing the selected environment (e.g. `device`, `simulator`)  or `None` if
        no constraint is found.
    """
    device_constraint = ctx.attr._apple_device_constraint[platform_common.ConstraintValueInfo]
    simulator_constraint = ctx.attr._apple_simulator_constraint[platform_common.ConstraintValueInfo]

    if ctx.target_platform_has_constraint(device_constraint):
        return "device"
    elif ctx.target_platform_has_constraint(simulator_constraint):
        return "simulator"
    if not fail_on_missing_constraint:
        return None
    fail("ERROR: A valid Apple environment (device, simulator) constraint could not be found from" +
         " the resolved toolchain.")

def _target_os_from_rule_ctx(
        ctx,
        *,
        fail_on_missing_constraint = True):
    """Returns a `String` representing the target OS based on constraints.

    The returned `String` will match an equivalent value from one of the platform definitions in
    `apple_common.platform_type`, such as `ios` or `macos`.

    In order to use `apple_support.target_os_from_rule_ctx()`, you'll need to modify your rule
    definition to add the following:

      * Add the `apple_support.platform_constraint_attrs()` attributes to the `attrs` dictionary.
        This can be done using the `dicts.add()` method from Skylib.

    Args:
        ctx: The context of the rule that has Apple platform constraint attributes.
        fail_on_missing_constraint: Whether to fail if no constraint is found. (default: `True`)

    Returns:
        A `String` representing the selected Apple OS or `None` if no constraint is found.
    """
    ios_constraint = ctx.attr._ios_constraint[platform_common.ConstraintValueInfo]
    macos_constraint = ctx.attr._macos_constraint[platform_common.ConstraintValueInfo]
    tvos_constraint = ctx.attr._tvos_constraint[platform_common.ConstraintValueInfo]
    visionos_constraint = ctx.attr._visionos_constraint[platform_common.ConstraintValueInfo]
    watchos_constraint = ctx.attr._watchos_constraint[platform_common.ConstraintValueInfo]

    if ctx.target_platform_has_constraint(ios_constraint):
        return str(apple_common.platform_type.ios)
    elif ctx.target_platform_has_constraint(macos_constraint):
        return str(apple_common.platform_type.macos)
    elif ctx.target_platform_has_constraint(tvos_constraint):
        return str(apple_common.platform_type.tvos)
    elif ctx.target_platform_has_constraint(visionos_constraint):
        return str(apple_common.platform_type.visionos)
    elif ctx.target_platform_has_constraint(watchos_constraint):
        return str(apple_common.platform_type.watchos)
    if not fail_on_missing_constraint:
        return None
    fail("ERROR: A valid Apple platform constraint could not be found from the resolved toolchain.")

def _platform_from_info(*, apple_platform_info):
    """Returns an apple_common.platform given the contents of an ApplePlatformInfo provider"""
    if apple_platform_info.target_os == "ios":
        if apple_platform_info.target_environment == "device":
            return apple_common.platform.ios_device
        elif apple_platform_info.target_environment == "simulator":
            return apple_common.platform.ios_simulator
    elif apple_platform_info.target_os == "macos":
        return apple_common.platform.macos
    elif apple_platform_info.target_os == "tvos":
        if apple_platform_info.target_environment == "device":
            return apple_common.platform.tvos_device
        elif apple_platform_info.target_environment == "simulator":
            return apple_common.platform.tvos_simulator
    elif apple_platform_info.target_os == "visionos":
        if apple_platform_info.target_environment == "device":
            return apple_common.platform.visionos_device
        elif apple_platform_info.target_environment == "simulator":
            return apple_common.platform.visionos_simulator
    elif apple_platform_info.target_os == "watchos":
        if apple_platform_info.target_environment == "device":
            return apple_common.platform.watchos_device
        elif apple_platform_info.target_environment == "simulator":
            return apple_common.platform.watchos_simulator
    else:
        fail("Internal Error: Found unrecognized target os of " + apple_platform_info.target_os)
    fail(
        """
Internal Error: Found unrecognized target environment of {target_environment} for os {target_os}
""".format(
            target_environment = apple_platform_info.target_environment,
            target_os = apple_platform_info.target_os,
        ),
    )

def _platform_info_from_rule_ctx(ctx, fail_on_missing_constraint = True):
    """Returns `ApplePlatformInfo` from a rule context, required for Apple platform information.

    In order to use `apple_support.platform_info_from_rule_ctx()`, you'll need to modify your rule
    definition to add the following:

      * Add the `apple_support.platform_constraint_attrs()` attributes to the `attrs` dictionary.
        This can be done using the `dicts.add()` method from Skylib or via the `|` operator.

    Args:
        ctx: The context of the rule that has Apple platform constraint attributes.
        fail_on_missing_constraint: Whether to fail if no constraint is found. If `False`, a
            fallback platform of Apple Silicon macOS will be used if no Apple platform was found
            from the current target configuration. If `True`, the function will fail if no Apple
            platform is found and the target is not in the
            `ALLOWED_USERS_OF_MISSING_PLATFORM_FALLBACK` allowlist.

    Returns:
        An `ApplePlatformInfo` representing the resolved Apple platform.
    """
    target_os = _target_os_from_rule_ctx(
        ctx,
        fail_on_missing_constraint = False,
    )
    if not target_os:
        full_label = "//{package}:{name}".format(package = ctx.label.package, name = ctx.label.name)
        if (fail_on_missing_constraint and
            full_label not in ALLOWED_USERS_OF_MISSING_PLATFORM_FALLBACK):
            fail("""
ERROR: A valid Apple platform constraint could not be found for target {full_label}

Check that you are building this target for a supported Apple platform (ios, macos, tvos, \
visionos, watchos) and that it is not accidentally being built with a default config, such as Linux.

Specifically, you need to have your configuration for the `build` or `test` command updated to \
specify an Apple platform, potentially via a config such as `--config=darwin_arm64` or directly \
through `--platforms` rather than relying on the defaults.
""".format(
                full_label = full_label,
            ))

        if fail_on_missing_constraint:
            # Starlark-only default fallback when Apple constraints are missing (e.g. Linux host analysis)
            # buildifier: disable=print
            print("Warning: Target {} is analyzed without Apple platform constraints. Applying temporary macos fallback.".format(full_label))
        target_os = "macos"
        target_env = "device"
        target_arch = "arm64"
    else:
        target_env = _target_environment_from_rule_ctx(ctx)
        target_arch = _target_arch_from_rule_ctx(ctx)

    platform = _platform_from_info(
        apple_platform_info = struct(target_os = target_os, target_environment = target_env),
    )

    return new_appleplatforminfo(
        target_arch = target_arch,
        target_build_config = ctx.configuration,
        target_environment = target_env,
        target_os = target_os,
        platform = platform,
    )

apple_support = struct(
    action_required_attrs = _action_required_attrs,
    path_placeholders = struct(
        platform_frameworks = _platform_frameworks_path_placeholder,
        sdkroot = _sdkroot_path_placeholder,
        xcode = _xcode_path_placeholder,
    ),
    platform_constraint_attrs = _platform_constraint_attrs,
    platform_info_from_rule_ctx = _platform_info_from_rule_ctx,
    run = _run,
    run_shell = _run_shell,
    target_arch_from_rule_ctx = _target_arch_from_rule_ctx,
    target_environment_from_rule_ctx = _target_environment_from_rule_ctx,
    target_os_from_rule_ctx = _target_os_from_rule_ctx,
    xcode_path_resolve_level = _XCODE_PATH_RESOLVE_LEVEL,
)
