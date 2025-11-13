<!-- Generated with Stardoc, Do Not Edit! -->

# `apple_support` starlark module

A module of helpers for rule authors to aid in writing actions that target
Apple platforms.

To use these in your Starlark code, simply load the module; for example:

```build
load("@build_bazel_apple_support//lib:apple_support.bzl", "apple_support")
```
On this page:

  * [apple_support.action_required_attrs](#apple_support.action_required_attrs)
  * [apple_support.path_placeholders.platform_frameworks](#apple_support.path_placeholders.platform_frameworks)
  * [apple_support.path_placeholders.sdkroot](#apple_support.path_placeholders.sdkroot)
  * [apple_support.path_placeholders.xcode](#apple_support.path_placeholders.xcode)
  * [apple_support.platform_constraint_attrs](#apple_support.platform_constraint_attrs)
  * [apple_support.run](#apple_support.run)
  * [apple_support.run_shell](#apple_support.run_shell)
  * [apple_support.target_arch_from_rule_ctx](#apple_support.target_arch_from_rule_ctx)
  * [apple_support.target_environment_from_rule_ctx](#apple_support.target_environment_from_rule_ctx)
  * [apple_support.target_os_from_rule_ctx](#apple_support.target_os_from_rule_ctx)
  * [apple_support.xcode_path_resolve_level](#apple_support.xcode_path_resolve_level)

<a id="apple_support.action_required_attrs"></a>

## apple_support.action_required_attrs

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

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



**RETURNS**

A `dict` object containing attributes to be added to rule implementations.


<a id="apple_support.path_placeholders.platform_frameworks"></a>

## apple_support.path_placeholders.platform_frameworks

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.path_placeholders.platform_frameworks(*, <a href="#apple_support.path_placeholders.platform_frameworks-apple_fragment">apple_fragment</a>)
</pre>

Returns the platform's frameworks directory, anchored to the Xcode path placeholder.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="apple_support.path_placeholders.platform_frameworks-apple_fragment"></a>apple_fragment |  A reference to the apple fragment. Typically from `ctx.fragments.apple`.   |  none |

**RETURNS**

Returns a string with the platform's frameworks directory, anchored to the Xcode path
  placeholder.


<a id="apple_support.path_placeholders.sdkroot"></a>

## apple_support.path_placeholders.sdkroot

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.path_placeholders.sdkroot()
</pre>

Returns a placeholder value to be replaced with SDKROOT during action execution.

In order to get this values replaced, you'll need to use the `apple_support.run()` API by
setting the `xcode_path_resolve_level` argument to either the
`apple_support.xcode_path_resolve_level.args` or
`apple_support.xcode_path_resolve_level.args_and_files` value.



**RETURNS**

Returns a placeholder value to be replaced with SDKROOT during action execution.


<a id="apple_support.path_placeholders.xcode"></a>

## apple_support.path_placeholders.xcode

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.path_placeholders.xcode()
</pre>

Returns a placeholder value to be replaced with DEVELOPER_DIR during action execution.

In order to get this values replaced, you'll need to use the `apple_support.run()` API by
setting the `xcode_path_resolve_level` argument to either the
`apple_support.xcode_path_resolve_level.args` or
`apple_support.xcode_path_resolve_level.args_and_files` value.



**RETURNS**

Returns a placeholder value to be replaced with DEVELOPER_DIR during action execution.


<a id="apple_support.platform_constraint_attrs"></a>

## apple_support.platform_constraint_attrs

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.platform_constraint_attrs()
</pre>

Returns a dictionary of all known Apple platform constraints that can be resolved.

The returned `dict` can be added to the rule's attributes using Skylib's `dicts.add()` method.



**RETURNS**

A `dict` object containing attributes to be added to rule implementations.


<a id="apple_support.run"></a>

## apple_support.run

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.run(*, <a href="#apple_support.run-actions">actions</a>, <a href="#apple_support.run-xcode_config">xcode_config</a>, <a href="#apple_support.run-apple_fragment">apple_fragment</a>, <a href="#apple_support.run-xcode_path_resolve_level">xcode_path_resolve_level</a>, <a href="#apple_support.run-kwargs">**kwargs</a>)
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
| :------------- | :------------- | :------------- |
| <a id="apple_support.run-actions"></a>actions |  The actions provider from ctx.actions.   |  none |
| <a id="apple_support.run-xcode_config"></a>xcode_config |  The xcode_config as found in the current rule or aspect's context. Typically from `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.   |  none |
| <a id="apple_support.run-apple_fragment"></a>apple_fragment |  A reference to the apple fragment. Typically from `ctx.fragments.apple`.   |  none |
| <a id="apple_support.run-xcode_path_resolve_level"></a>xcode_path_resolve_level |  The level of Xcode path replacement required for the action.   |  `None` |
| <a id="apple_support.run-kwargs"></a>kwargs |  See `ctx.actions.run` for the rest of the available arguments.   |  none |


<a id="apple_support.run_shell"></a>

## apple_support.run_shell

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.run_shell(*, <a href="#apple_support.run_shell-actions">actions</a>, <a href="#apple_support.run_shell-xcode_config">xcode_config</a>, <a href="#apple_support.run_shell-apple_fragment">apple_fragment</a>, <a href="#apple_support.run_shell-kwargs">**kwargs</a>)
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
| :------------- | :------------- | :------------- |
| <a id="apple_support.run_shell-actions"></a>actions |  The actions provider from ctx.actions.   |  none |
| <a id="apple_support.run_shell-xcode_config"></a>xcode_config |  The xcode_config as found in the current rule or aspect's context. Typically from `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`.   |  none |
| <a id="apple_support.run_shell-apple_fragment"></a>apple_fragment |  A reference to the apple fragment. Typically from `ctx.fragments.apple`.   |  none |
| <a id="apple_support.run_shell-kwargs"></a>kwargs |  See `ctx.actions.run_shell` for the rest of the available arguments.   |  none |


<a id="apple_support.target_arch_from_rule_ctx"></a>

## apple_support.target_arch_from_rule_ctx

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.target_arch_from_rule_ctx(<a href="#apple_support.target_arch_from_rule_ctx-ctx">ctx</a>, *, <a href="#apple_support.target_arch_from_rule_ctx-fail_on_missing_constraint">fail_on_missing_constraint</a>)
</pre>

Returns a `String` representing the target architecture based on constraints.

The returned `String` will represent a cpu architecture, such as `arm64` or `arm64e`.

In order to use `apple_support.target_arch_from_rule_ctx()`, you'll need to modify your rule
definition to add the following:

  * Add the `apple_support.platform_constraint_attrs()` attributes to the `attrs` dictionary.
    This can be done using the `dicts.add()` method from Skylib.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="apple_support.target_arch_from_rule_ctx-ctx"></a>ctx |  The context of the rule that has Apple platform constraint attributes.   |  none |
| <a id="apple_support.target_arch_from_rule_ctx-fail_on_missing_constraint"></a>fail_on_missing_constraint |  Whether to fail if no constraint is found. (default: `True`)   |  `True` |

**RETURNS**

A `String` representing the selected target architecture or cpu type (e.g. `arm64`,
  `arm64e`) or `None` if no constraint is found.


<a id="apple_support.target_environment_from_rule_ctx"></a>

## apple_support.target_environment_from_rule_ctx

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.target_environment_from_rule_ctx(<a href="#apple_support.target_environment_from_rule_ctx-ctx">ctx</a>, *, <a href="#apple_support.target_environment_from_rule_ctx-fail_on_missing_constraint">fail_on_missing_constraint</a>)
</pre>

Returns a `String` representing the target environment based on constraints.

The returned `String` will represent an environment, such as `device` or `simulator`.

For consistency with other Apple platforms, `macos` is considered to be a `device`.

In order to use `apple_support.target_environment_from_rule_ctx()`, you'll need to modify your
rule definition to add the following:

  * Add the `apple_support.platform_constraint_attrs()` attributes to the `attrs` dictionary.
    This can be done using the `dicts.add()` method from Skylib.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="apple_support.target_environment_from_rule_ctx-ctx"></a>ctx |  The context of the rule that has Apple platform constraint attributes.   |  none |
| <a id="apple_support.target_environment_from_rule_ctx-fail_on_missing_constraint"></a>fail_on_missing_constraint |  Whether to fail if no constraint is found. (default: `True`)   |  `True` |

**RETURNS**

A `String` representing the selected environment (e.g. `device`, `simulator`)  or `None` if
  no constraint is found.


<a id="apple_support.target_os_from_rule_ctx"></a>

## apple_support.target_os_from_rule_ctx

<pre>
load("@apple_support//lib:apple_support.bzl", "apple_support")

apple_support.target_os_from_rule_ctx(<a href="#apple_support.target_os_from_rule_ctx-ctx">ctx</a>, *, <a href="#apple_support.target_os_from_rule_ctx-fail_on_missing_constraint">fail_on_missing_constraint</a>)
</pre>

Returns a `String` representing the target OS based on constraints.

The returned `String` will match an equivalent value from one of the platform definitions in
`apple_common.platform_type`, such as `ios` or `macos`.

In order to use `apple_support.target_os_from_rule_ctx()`, you'll need to modify your rule
definition to add the following:

  * Add the `apple_support.platform_constraint_attrs()` attributes to the `attrs` dictionary.
    This can be done using the `dicts.add()` method from Skylib.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="apple_support.target_os_from_rule_ctx-ctx"></a>ctx |  The context of the rule that has Apple platform constraint attributes.   |  none |
| <a id="apple_support.target_os_from_rule_ctx-fail_on_missing_constraint"></a>fail_on_missing_constraint |  Whether to fail if no constraint is found. (default: `True`)   |  `True` |

**RETURNS**

A `String` representing the selected Apple OS or `None` if no constraint is found.


