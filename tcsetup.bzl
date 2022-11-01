"""TODO"""

def _impl(repository_ctx):
    """Generate BUILD file with 'toolchain' targets for the local host C++ toolchain.

    Args:
      repository_ctx: repository context
    """
    env = repository_ctx.os.environ

    # Should we try to find C++ toolchain at all? If not, we don't have to generate toolchains for C++ at all.
    should_detect_cpp_toolchain = "BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN" not in env or env["BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN"] != "1"

    # Should we unconditionally *not* use xcode? If so, we don't have to run Xcode locator ever.
    should_use_cpp_only_toolchain = "BAZEL_USE_CPP_ONLY_TOOLCHAIN" in env and env["BAZEL_USE_CPP_ONLY_TOOLCHAIN"] == "1"

    if not should_detect_cpp_toolchain:
        repository_ctx.file("BUILD", "# Apple C++ toolchain autoconfiguration was disabled by BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN env variable.")
    elif should_use_cpp_only_toolchain:
        repository_ctx.file("BUILD", "# Apple C++ toolchain autoconfiguration was disabled by BAZEL_USE_CPP_ONLY_TOOLCHAIN env variable.")
    elif repository_ctx.os.name.startswith("mac os"):
        repository_ctx.symlink(
            repository_ctx.path(Label("//:BUILD.toolchains")),
            "BUILD",
        )
    else:
        repository_ctx.file("BUILD", "# Apple C++ toolchain autoconfiguration was disabled because you're not running on macOS")

apple_cc_autoconf_toolchains = repository_rule(
    environ = [
        "BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN",
        "BAZEL_USE_CPP_ONLY_TOOLCHAIN",
    ],
    implementation = _impl,
    configure = True,
)

# buildifier: disable=unnamed-macro
def apple_cc_configure():
    apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")
    native.register_toolchains(
        # Use register_toolchain's target pattern expansion to register all toolchains in the package.
        "@local_config_apple_cc_toolchains//:all",
    )
