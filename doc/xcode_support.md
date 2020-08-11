<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#xcode_support.is_xcode_at_least_version"></a>

## xcode_support.is_xcode_at_least_version

<pre>
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
| :-------------: | :-------------: | :-------------: |
| xcode_config |  The XcodeVersionConfig provider from the <code>_xcode_config</code> attribute's value.   |  none |
| version |  The minimum desired Xcode version, as a dotted version string.   |  none |


