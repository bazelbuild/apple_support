<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#apple_support_dependencies"></a>

## apple_support_dependencies

<pre>
apple_support_dependencies()
</pre>

Fetches repository dependencies of the `apple_support` workspace.

Users should call this macro in their `WORKSPACE` to ensure that all of the
dependencies of the Swift rules are downloaded and that they are isolated from
changes to those dependencies.

**PARAMETERS**



