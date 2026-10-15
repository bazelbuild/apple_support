<!-- Generated with Stardoc, Do Not Edit! -->

# Minimum Xcode version conditions

Use `xcode_version_at_least` in BUILD files to configure attributes based on the
selected Xcode version.
On this page:

  * [xcode_version_at_least](#xcode_version_at_least)

<a id="xcode_version_at_least"></a>

## xcode_version_at_least

<pre>
load("@apple_support//xcode:xcode_version_at_least.bzl", "xcode_version_at_least")

xcode_version_at_least(*, <a href="#xcode_version_at_least-name">name</a>, <a href="#xcode_version_at_least-minimum_xcode_version">minimum_xcode_version</a>, <a href="#xcode_version_at_least-after">after</a>, <a href="#xcode_version_at_least-visibility">visibility</a>, <a href="#xcode_version_at_least-kwargs">**kwargs</a>)
</pre>

Creates a `config_setting` target that matches when Xcode is at least `minimum_xcode_version`.

The condition compares the resolved Xcode version, including when Xcode is
selected by default without an explicit `--xcode_version` flag. It does not
match if the resolved configuration has no Xcode version.

For example, enable a definition with Xcode 26.4 or newer:

```starlark
load("@apple_support//xcode:xcode_version_at_least.bzl", "xcode_version_at_least")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

xcode_version_at_least(
    name = "xcode_26_4_or_newer",
    minimum_xcode_version = "26.4",
)

cc_library(
    name = "example",
    srcs = ["example.cc"],
    defines = select({
        ":xcode_26_4_or_newer": ["HAS_XCODE_26_4"],
        "//conditions:default": [],
    }),
)
```

When multiple thresholds appear in the same `select()`, use `after` to make
the higher threshold specialize the lower one. Continuing the example above:

```starlark
xcode_version_at_least(
    name = "xcode_27_or_newer",
    minimum_xcode_version = "27",
    after = [":xcode_26_4_or_newer"],
)

cc_library(
    name = "versioned_example",
    srcs = ["example.cc"],
    defines = select({
        ":xcode_27_or_newer": ["XCODE_LEVEL=27"],
        ":xcode_26_4_or_newer": ["XCODE_LEVEL=26"],
        "//conditions:default": ["XCODE_LEVEL=0"],
    }),
)
```

With Xcode 27 or newer, both conditions match, but the more specialized
`xcode_27_or_newer` branch wins. Without `after`, different values for these
overlapping conditions would make the `select()` ambiguous.

Declare lower thresholds before higher thresholds and use local target names
or `:name` labels to inherit a same-package `after` chain transitively. For
cross-package or fully qualified references, list every lower threshold in
the chain explicitly. Each threshold must be strictly higher than those in
its `after` list.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="xcode_version_at_least-name"></a>name |  The name of the `config_setting` target to create. A companion feature flag target named `<name>_flag` will also be created.   |  none |
| <a id="xcode_version_at_least-minimum_xcode_version"></a>minimum_xcode_version |  The minimum Xcode version to match (inclusive), such as `"26.4"`, `"26.4.1"`, or `"27.0.0.27A5228h"`.   |  none |
| <a id="xcode_version_at_least-after"></a>after |  An optional list of lower-version `xcode_version_at_least` target names or labels that this condition should refine when used together in the same `select()` expression. If a referenced target is in the same package, any lower thresholds it already refines are inherited transitively.   |  `None` |
| <a id="xcode_version_at_least-visibility"></a>visibility |  The visibility of the generated targets.   |  `None` |
| <a id="xcode_version_at_least-kwargs"></a>kwargs |  Additional keyword arguments (such as `tags` or `constraint_values`) forwarded to `native.config_setting`. `tags` is also forwarded to the companion `<name>_flag` target.   |  none |


