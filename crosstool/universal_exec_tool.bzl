"""Rules for creating exec-configured universal tools for repository rules."""

load("@build_bazel_apple_support//rules:apple_genrule.bzl", "apple_genrule")

def _force_exec_impl(ctx):
    default_into = ctx.attr.target[DefaultInfo]

    return [
        DefaultInfo(
            files = depset(transitive = [default_into.files]),
        ),
    ]

force_exec = rule(
    attrs = {
        "target": attr.label(
            cfg = "exec",
            allow_single_file = True,
            mandatory = True,
        ),
    },
    implementation = _force_exec_impl,
)

def universal_exec_tool(*, name, out, srcs):
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
    -mmacosx-version-min=10.15 \
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
