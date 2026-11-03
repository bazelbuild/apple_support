"""Rules for creating exec-configured universal tools for repository rules."""

load("//rules:apple_genrule.bzl", "apple_genrule")

def _force_exec_impl(ctx):
    # type: (...) -> list[DefaultInfo]
    default_into = ctx.attr.target[DefaultInfo]

    return [
        DefaultInfo(
            files = depset(transitive = [default_into.files]),
        ),
    ]

# TODO: Remove once we drop bazel 8.x and the legacy toolchain
force_exec = rule(
    attrs = {
        "target": attr.label(
            cfg = "exec",
            allow_single_file = True,
            mandatory = True,
        ),
    },
    implementation = _force_exec_impl,
    exec_compatible_with = ["@platforms//os:macos"],
)

# TODO(https://github.com/bazelbuild/bazel/issues/32021): Use native annotations
# once supported Bazel versions expose depset element types.
# type _Labels = Collection[Label | str] | depset[Label | str]

# TODO(https://github.com/tamird/sty/blob/sty-action-v0.2.0/docs/type-interfaces.md#selectors):
# Use a native parameter annotation when Bazel can describe configurable srcs
# whose selected value can be a list, a depset, or None.
def universal_exec_tool(*, name, out, srcs):
    # type: (str, Label | str, _Labels | select[_Labels | None] | None) -> None
    apple_genrule(
        name = name + ".target_config",
        srcs = srcs,
        outs = [out],
        cmd = """
env -i \
  DEVELOPER_DIR="$${DEVELOPER_DIR:-}" \
  xcrun \
    --sdk macosx \
    clang \
    -mmacosx-version-min=11.0 \
    -std=c++17 \
    -lc++ \
    -arch arm64 \
    -arch x86_64 \
    -O3 \
    -o $@ \
    $(SRCS)
""",
    )

    force_exec(
        name = name,
        target = ":{}.target_config".format(name),
    )
