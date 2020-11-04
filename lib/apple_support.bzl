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

# Options to declare the level of Xcode path resolving needed in an `apple_support.run()`
# invocation.
_XCODE_PATH_RESOLVE_LEVEL = struct(
    none = None,
    args = "args",
    args_and_files = "args_and_files",
)

def _validate_ctx_xor_platform_requirements(*, ctx, xcode_config, apple_fragment):
    """Raises an error if there is overlap in platform requirements or if they are insufficent."""

    if ctx != None and (xcode_config != None or apple_fragment != None):
        fail("Can't specify ctx with xcode_config or apple_fragment.")
    elif ctx == None and (xcode_config == None or apple_fragment == None):
        fail("Must specify either ctx or xcode_config with apple_fragment.")
    elif ctx != None:
        _validate_ctx_attribute_present(ctx, "_xcode_config")

def _validate_actions_arg_requirements(*, ctx, actions):
    """Raises an error if both ctx and actions are provided, or none are."""

    if ctx != None and actions != None:
        fail("Can't specify actions if ctx was provided.")
    elif ctx == None and actions == None:
        fail("Must specify actions with xcode_config and apple_fragment.")

def _platform_frameworks_path_placeholder(ctx = None, *, apple_fragment = None):
    """Returns the platform's frameworks directory, anchored to the Xcode path placeholder.

    Args:
        ctx: The context of the rule that will register an action. Deprecated.
        apple_fragment: A reference to the apple fragment. Typically from `ctx.fragments.apple`.
            Required if ctx is not given.

    Returns:
        Returns a string with the platform's frameworks directory, anchored to the Xcode path
        placeholder.
    """
    if ctx != None and apple_fragment != None:
        fail("Can't specify ctx with apple_fragment.")
    elif ctx == None and apple_fragment == None:
        fail("Must specify either ctx or apple_fragment.")
    elif ctx != None:
        apple_fragment = ctx.fragments.apple
    return "{xcode_path}/Platforms/{platform_name}.platform/Developer/Library/Frameworks".format(
        platform_name = apple_fragment.single_arch_platform.name_in_plist,
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

def _add_dicts(*dictionaries):
    """Adds a list of dictionaries into a single dictionary."""

    # If keys are repeated in multiple dictionaries, the latter one "wins".
    result = {}
    for d in dictionaries:
        result.update(d)

    return result

def _kwargs_for_apple_platform(
        ctx = None,
        additional_env = None,
        *,
        xcode_config = None,
        apple_fragment = None,
        **kwargs):
    """Returns a modified dictionary with required arguments to run on Apple platforms."""
    _validate_ctx_xor_platform_requirements(
        ctx = ctx,
        xcode_config = xcode_config,
        apple_fragment = apple_fragment,
    )

    processed_args = dict(kwargs)

    env_dicts = []
    original_env = processed_args.get("env")
    if original_env:
        env_dicts.append(original_env)
    if additional_env:
        env_dicts.append(additional_env)

    # Add the environment variables required for DEVELOPER_DIR and SDKROOT last to avoid clients
    # overriding this value.
    if xcode_config != None and apple_fragment != None:
        env_dicts.append(_action_required_env(
            xcode_config = xcode_config,
            apple_fragment = apple_fragment,
        ))
        action_execution_requirements = apple_support.action_required_execution_requirements(
            xcode_config = xcode_config,
        )
    else:
        env_dicts.append(_action_required_env(ctx))
        action_execution_requirements = apple_support.action_required_execution_requirements(ctx)

    execution_requirement_dicts = []
    original_execution_requirements = processed_args.get("execution_requirements")
    if original_execution_requirements:
        execution_requirement_dicts.append(original_execution_requirements)

    # Add the execution requirements last to avoid clients overriding this value.
    execution_requirement_dicts.append(action_execution_requirements)

    processed_args["env"] = _add_dicts(*env_dicts)
    processed_args["execution_requirements"] = _add_dicts(*execution_requirement_dicts)

    return processed_args

def _validate_ctx_attribute_present(ctx, attribute_name):
    """Validates that the given attribute is present for the rule, failing otherwise."""
    if not hasattr(ctx.attr, attribute_name):
        fail("\n".join([
            "",
            "ERROR: This rule requires the '{}' attribute to be present. ".format(attribute_name),
            "To add this attribute, modify your rule definition like this:",
            "",
            "load(\"@bazel_skylib//lib:dicts.bzl\", \"dicts\")",
            "load(",
            "    \"@build_bazel_apple_support//lib:apple_support.bzl\",",
            "    \"apple_support\",",
            ")",
            "",
            "your_rule_name = rule(",
            "    attrs = dicts.add(apple_support.action_required_attrs(), {",
            "        # other attributes",
            "    }),",
            "    # other rule arguments",
            ")",
            "",
        ]))

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
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
        "_xcode_path_wrapper": attr.label(
            cfg = "host",
            executable = True,
            default = Label("@build_bazel_apple_support//tools:xcode_path_wrapper"),
        ),
    }

def _action_required_env(
        ctx = None,
        *,
        xcode_config = None,
        apple_fragment = None):
    """Returns a dictionary with the environment variables required for Xcode path resolution.

    In most cases, you should _not_ use this API. It exists solely for using it on test rules,
    where the test action registration API is not available in Starlark.

    To use these environment variables for a test, your test rule needs to propagate the
    `testing.TestEnvironment` provider, which takes a dictionary with environment variables to set
    during the test execution.

    Args:
        ctx: The context of the rule registering the action.
        xcode_config: The xcode_config as found in the current rule or aspect's
            context. Typically from `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.
            Required if ctx is not given.
        apple_fragment: A reference to the apple fragment. Typically from `ctx.fragments.apple`.
            Required if ctx is not given.

    Returns:
        A dictionary with environment variables required for Xcode path resolution.
    """
    _validate_ctx_xor_platform_requirements(
        ctx = ctx,
        xcode_config = xcode_config,
        apple_fragment = apple_fragment,
    )

    if apple_fragment != None:
        platform = apple_fragment.single_arch_platform
    else:
        platform = ctx.fragments.apple.single_arch_platform
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]

    return _add_dicts(
        apple_common.apple_host_system_env(xcode_config),
        apple_common.target_apple_env(xcode_config, platform),
    )

def _action_required_execution_requirements(ctx = None, *, xcode_config = None):
    """Returns a dictionary with the execution requirements for running actions on Apple platforms.

    In most cases, you should _not_ use this API. It exists solely for using it on test rules,
    where the test action registration API is not available in Starlark.

    To use these environment variables for a test, your test rule needs to propagate the
    `testing.TestExecution` provider, which takes a dictionary with execution requirements for the
    test action.

    Args:
        ctx: The context of the rule registering the action. Deprecated.
        xcode_config: The xcode_config as found in the current rule or aspect's
            context. Typically from `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.
            Required if ctx is not given.

    Returns:
        A dictionary with execution requirements for running actions on Apple platforms.
    """

    # TODO(steinman): Replace this with xcode_config.execution_info once it is exposed.
    if ctx != None and xcode_config != None:
        fail("Can't specify both ctx and xcode_config.")
    elif ctx == None and xcode_config == None:
        fail("Must specify either ctx or xcode_config.")
    execution_requirements = {"requires-darwin": "1"}
    if not xcode_config:
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    if xcode_config:
        if xcode_config.availability() == "remote":
            execution_requirements["no-local"] = "1"
        elif xcode_config.availability() == "local":
            execution_requirements["no-remote"] = "1"
        execution_requirements["supports-xcode-requirements-set"] = "1"
    return execution_requirements

def _run(
        ctx = None,
        xcode_path_resolve_level = _XCODE_PATH_RESOLVE_LEVEL.none,
        *,
        actions = None,
        xcode_config = None,
        apple_fragment = None,
        xcode_path_wrapper = None,
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
        ctx: The context of the rule registering the action. Deprecated.
        xcode_path_resolve_level: The level of Xcode path replacement required for the action.
        actions: The actions provider from ctx.actions. Required if ctx is not given.
        xcode_config: The xcode_config as found in the current rule or aspect's
            context. Typically from `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.
            Required if ctx is not given.
        apple_fragment: A reference to the apple fragment. Typically from `ctx.fragments.apple`.
            Required if ctx is not given.
        xcode_path_wrapper: The Xcode path wrapper script. Required if ctx is not given and
            xcode_path_resolve_level is not `apple_support.xcode_path_resolve_level.none`.
        **kwargs: See `ctx.actions.run` for the rest of the available arguments.
    """
    _validate_actions_arg_requirements(
        ctx = ctx,
        actions = actions,
    )

    if not actions:
        actions = ctx.actions

    if xcode_path_resolve_level == _XCODE_PATH_RESOLVE_LEVEL.none:
        actions.run(**_kwargs_for_apple_platform(
            ctx = ctx,
            xcode_config = xcode_config,
            apple_fragment = apple_fragment,
            **kwargs
        ))
        return

    if ctx == None and xcode_path_wrapper == None:
        fail("Must specify xcode_path_wrapper with xcode_config and apple_fragment.")
    elif ctx != None and xcode_path_wrapper != None:
        fail("Can't specify xcode_path_wrapper if ctx was provided.")
    elif not xcode_path_wrapper:
        _validate_ctx_attribute_present(ctx, "_xcode_path_wrapper")
        xcode_path_wrapper = ctx.executable._xcode_path_wrapper

    processed_kwargs = _kwargs_for_apple_platform(
        ctx,
        additional_env = {"XCODE_PATH_RESOLVE_LEVEL": xcode_path_resolve_level},
        **kwargs
    )

    all_arguments = []

    # If the client requires Xcode path resolving, push the original executable to be the first
    # argument, as the executable will be set to be the xcode_path_wrapper script.
    executable_args = actions.args()
    original_executable = processed_kwargs.pop("executable")
    executable_args.add(original_executable)
    all_arguments.append(executable_args)

    # Append the original arguments to the full list of arguments, after the original executable.
    original_args_list = processed_kwargs.pop("arguments", [])
    if original_args_list:
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
        executable = xcode_path_wrapper,
        arguments = all_arguments,
        tools = all_tools,
        **processed_kwargs
    )

def _run_shell(
        ctx = None,
        *,
        actions = None,
        xcode_config = None,
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
        ctx: The context of the rule registering the action. Deprecated.
        actions: The actions provider from ctx.actions.
        xcode_config: The xcode_config as found in the current rule or aspect's
            context. Typically from `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.
            Required if ctx is not given.
        apple_fragment: A reference to the apple fragment. Typically from `ctx.fragments.apple`.
            Required if ctx is not given.
        **kwargs: See `ctx.actions.run` for the rest of the available arguments.
    """
    _validate_actions_arg_requirements(
        ctx = ctx,
        actions = actions,
    )

    if not actions:
        actions = ctx.actions

    actions.run_shell(**_kwargs_for_apple_platform(
        ctx = ctx,
        xcode_config = xcode_config,
        apple_fragment = apple_fragment,
        **kwargs
    ))

apple_support = struct(
    action_required_attrs = _action_required_attrs,
    action_required_env = _action_required_env,
    action_required_execution_requirements = _action_required_execution_requirements,
    path_placeholders = struct(
        platform_frameworks = _platform_frameworks_path_placeholder,
        sdkroot = _sdkroot_path_placeholder,
        xcode = _xcode_path_placeholder,
    ),
    run = _run,
    run_shell = _run_shell,
    xcode_path_resolve_level = _XCODE_PATH_RESOLVE_LEVEL,
)
