<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#apple_support.action_required_attrs"></a>

## apple_support.action_required_attrs

<pre>
apple_support.action_required_attrs()
</pre>

Returns a dictionary with required attributes for registering actions on Apple platforms.

This method adds private attributes which should not be used outside of the apple_support
codebase. It also adds the following attributes which are considered to be public for rule
maintainers to use:

 * `_xcode_config`: Attribute that references a target containing the single
   `apple_common.XcodeVersionConfig` provider. This provider can be used to inspect Xcode-related
   properties about the Xcode being used for the build, as specified with the `--xcode_version`
   Bazel flag. The most common way to retrieve this provider is:
   `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.

The returned `dict` can be added to the rule's attributes using Skylib's `dicts.add()` method.


**PARAMETERS**



<a name="#apple_support.action_required_env"></a>

## apple_support.action_required_env

<pre>
apple_support.action_required_env(<a href="#apple_support.action_required_env-ctx">ctx</a>)
</pre>

Returns a dictionary with the environment variables required for Xcode path resolution.

In most cases, you should _not_ use this API. It exists solely for using it on test rules,
where the test action registration API is not available in Starlark.

To use these environment variables for a test, your test rule needs to propagate the
`testing.TestEnvironment` provider, which takes a dictionary with environment variables to set
during the test execution.


**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| ctx |  The context of the rule registering the action.   |  none |


<a name="#apple_support.action_required_execution_requirements"></a>

## apple_support.action_required_execution_requirements

<pre>
apple_support.action_required_execution_requirements(<a href="#apple_support.action_required_execution_requirements-ctx">ctx</a>)
</pre>

Returns a dictionary with the execution requirements for running actions on Apple platforms.

In most cases, you should _not_ use this API. It exists solely for using it on test rules,
where the test action registration API is not available in Starlark.

To use these environment variables for a test, your test rule needs to propagate the
`testing.TestExecution` provider, which takes a dictionary with execution requirements for the
test action.


**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| ctx |  The context of the rule registering the action.   |  none |


<a name="#apple_support.path_placeholders.platform_frameworks"></a>

## apple_support.path_placeholders.platform_frameworks

<pre>
apple_support.path_placeholders.platform_frameworks(<a href="#apple_support.path_placeholders.platform_frameworks-ctx">ctx</a>)
</pre>

Returns the platform's frameworks directory, anchored to the Xcode path placeholder.

**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| ctx |  The context of the rule that will register an action.   |  none |


<a name="#apple_support.path_placeholders.sdkroot"></a>

## apple_support.path_placeholders.sdkroot

<pre>
apple_support.path_placeholders.sdkroot()
</pre>

Returns a placeholder value to be replaced with SDKROOT during action execution.

In order to get this values replaced, you'll need to use the `apple_support.run()` API by
setting the `xcode_path_resolve_level` argument to either the
`apple_support.xcode_path_resolve_level.args` or
`apple_support.xcode_path_resolve_level.args_and_files` value.


**PARAMETERS**



<a name="#apple_support.path_placeholders.xcode"></a>

## apple_support.path_placeholders.xcode

<pre>
apple_support.path_placeholders.xcode()
</pre>

Returns a placeholder value to be replaced with DEVELOPER_DIR during action execution.

In order to get this values replaced, you'll need to use the `apple_support.run()` API by
setting the `xcode_path_resolve_level` argument to either the
`apple_support.xcode_path_resolve_level.args` or
`apple_support.xcode_path_resolve_level.args_and_files` value.


**PARAMETERS**



<a name="#apple_support.run"></a>

## apple_support.run

<pre>
apple_support.run(<a href="#apple_support.run-ctx">ctx</a>, <a href="#apple_support.run-xcode_path_resolve_level">xcode_path_resolve_level</a>, <a href="#apple_support.run-kwargs">kwargs</a>)
</pre>

Registers an action to run on an Apple machine.

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


**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| ctx |  The context of the rule registering the action.   |  none |
| xcode_path_resolve_level |  The level of Xcode path replacement required for the action.   |  <code>None</code> |
| kwargs |  See <code>ctx.actions.run</code> for the rest of the available arguments.   |  none |


<a name="#apple_support.run_shell"></a>

## apple_support.run_shell

<pre>
apple_support.run_shell(<a href="#apple_support.run_shell-ctx">ctx</a>, <a href="#apple_support.run_shell-kwargs">kwargs</a>)
</pre>

Registers a shell action to run on an Apple machine.

In order to use `apple_support.run_shell()`, you'll need to modify your rule definition to add
the following:

  * `fragments = ["apple"]`
  * Add the `apple_support.action_required_attrs()` attributes to the `attrs` dictionary. This
    can be done using the `dicts.add()` method from Skylib.

This method registers an action to run on an Apple machine, configuring it to ensure that the
`DEVELOPER_DIR` and `SDKROOT` environment variables are set.

`run_shell` does not support placeholder substitution. To achieve placeholder substitution,
please use `run` instead.


**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| ctx |  The context of the rule registering the action.   |  none |
| kwargs |  See <code>ctx.actions.run</code> for the rest of the available arguments.   |  none |


