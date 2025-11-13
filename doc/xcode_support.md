<!-- Generated with Stardoc, Do Not Edit! -->

# `xcode_support` Starlark Module

A modules of helpers for rule authors to aid in writing rules that
need to change what they do based on attributes of the active Xcode.

To use these in your Starlark code, simply load the module; for example:

```build
load("@build_bazel_apple_support//lib:xcode_support.bzl", "xcode_support")
```
On this page:

  * [xcode_support.get_current_sdk](#xcode_support.get_current_sdk)
  * [xcode_support.get_current_xcode](#xcode_support.get_current_xcode)
  * [xcode_support.is_xcode_at_least_version](#xcode_support.is_xcode_at_least_version)

<a id="xcode_support.get_current_sdk"></a>

## xcode_support.get_current_sdk

<pre>
load("@apple_support//lib:xcode_support.bzl", "xcode_support")

xcode_support.get_current_sdk(<a href="#xcode_support.get_current_sdk-ctx">ctx</a>)
</pre>

Returns the `XcodeSdkVariantInfo` provider for the current configuration.

Callers of this function must define the `_xcode_config` attribute in their
rule or aspect. This is best done using the
`apple_support.action_required_attrs()` helper.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_support.get_current_sdk-ctx"></a>ctx |  The rule or aspect context.   |  none |

**RETURNS**

The `XcodeSdkVariantInfo` provider for the current configuration.


<a id="xcode_support.get_current_xcode"></a>

## xcode_support.get_current_xcode

<pre>
load("@apple_support//lib:xcode_support.bzl", "xcode_support")

xcode_support.get_current_xcode(<a href="#xcode_support.get_current_xcode-ctx">ctx</a>)
</pre>

Returns the `XcodeVersionConfig` provider for the current configuration.

Callers of this function must define the `_xcode_config` attribute in their
rule or aspect. This is best done using the
`apple_support.action_required_attrs()` helper.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_support.get_current_xcode-ctx"></a>ctx |  The rule or aspect context.   |  none |

**RETURNS**

The `XcodeVersionConfig` provider for the current configuration.


<a id="xcode_support.is_xcode_at_least_version"></a>

## xcode_support.is_xcode_at_least_version

<pre>
load("@apple_support//lib:xcode_support.bzl", "xcode_support")

xcode_support.is_xcode_at_least_version(<a href="#xcode_support.is_xcode_at_least_version-xcode_config">xcode_config</a>, <a href="#xcode_support.is_xcode_at_least_version-version">version</a>)
</pre>

Returns True if Xcode version is at least a given version.

This method takes as input an `XcodeVersionConfig` provider, which can be obtained from the
`_xcode_config` attribute (e.g. `ctx.attr._xcode_config[apple_common.XcodeVersionConfig]`). This
provider should contain the Xcode version parameters with which this rule is being built with.
If you need to add this attribute to your rule implementation, please refer to
`apple_support.action_required_attrs()`.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_support.is_xcode_at_least_version-xcode_config"></a>xcode_config |  The XcodeVersionConfig provider from the `_xcode_config` attribute's value.   |  none |
| <a id="xcode_support.is_xcode_at_least_version-version"></a>version |  The minimum desired Xcode version, as a dotted version string.   |  none |

**RETURNS**

True if the given `xcode_config` version at least as high as the requested version.


