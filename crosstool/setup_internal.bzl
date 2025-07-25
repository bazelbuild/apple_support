"""Configure the Apple CC toolchain"""

load("//crosstool:osx_cc_configure.bzl", "configure_osx_toolchain")

visibility("//lib/...")

_DISABLE_ENV_VAR = "BAZEL_NO_APPLE_CPP_TOOLCHAIN"
_OLD_DISABLE_ENV_VAR = "BAZEL_USE_CPP_ONLY_TOOLCHAIN"

def _apple_cc_autoconf_toolchains_impl(repository_ctx):
    """Generate BUILD file with 'toolchain' targets for the local host C++ toolchain.

    Args:
      repository_ctx: repository context
    """
    env = repository_ctx.os.environ
    should_disable = _DISABLE_ENV_VAR in env and env[_DISABLE_ENV_VAR] == "1"
    old_should_disable = _OLD_DISABLE_ENV_VAR in env and env[_OLD_DISABLE_ENV_VAR] == "1"

    if should_disable or old_should_disable:
        repository_ctx.file("BUILD", "# Apple CC toolchain autoconfiguration was disabled by {} env variable.".format(
            _DISABLE_ENV_VAR if should_disable else _OLD_DISABLE_ENV_VAR,
        ))
    else:
        repository_ctx.file(
            "BUILD",
            content = repository_ctx.read(
                Label("@build_bazel_apple_support//crosstool:BUILD.toolchains"),
            ),
        )

apple_cc_autoconf_toolchains = repository_rule(
    environ = [
        _DISABLE_ENV_VAR,
        _OLD_DISABLE_ENV_VAR,
    ],
    implementation = _apple_cc_autoconf_toolchains_impl,
    configure = True,
)

def _apple_cc_autoconf_impl(repository_ctx):
    env = repository_ctx.os.environ
    should_disable = _DISABLE_ENV_VAR in env and env[_DISABLE_ENV_VAR] == "1"
    old_should_disable = _OLD_DISABLE_ENV_VAR in env and env[_OLD_DISABLE_ENV_VAR] == "1"

    if should_disable or old_should_disable:
        repository_ctx.file("BUILD", "# Apple CC autoconfiguration was disabled by {} env variable.".format(
            _DISABLE_ENV_VAR if should_disable else _OLD_DISABLE_ENV_VAR,
        ))
    else:
        success, error = configure_osx_toolchain(repository_ctx)
        if not success:
            fail("Failed to configure Apple CC toolchain, if you only have the command line tools installed and not Xcode, you cannot use this toolchain. You should either remove it or temporarily set '{}=1' in the environment: {}".format(_DISABLE_ENV_VAR, error))

apple_cc_autoconf = repository_rule(
    environ = [
        _DISABLE_ENV_VAR,
        _OLD_DISABLE_ENV_VAR,
        "APPLE_SUPPORT_LAYERING_CHECK_BETA",
        "BAZEL_ALLOW_NON_APPLICATIONS_XCODE",  # Signals to configure_osx_toolchain that some Xcodes may live outside of /Applications and we need to probe further when detecting/configuring them.
        "DEVELOPER_DIR",  # Used for making sure we use the right Xcode for compiling toolchain binaries
        "GCOV",  # TODO: Remove this
        "USE_CLANG_CL",  # Kept as a hack for those who rely on this invaliding the toolchain
        "USER",  # Used to allow paths for custom toolchains to be used by C* compiles
        "XCODE_VERSION",  # Force re-computing the toolchain by including the current Xcode version info in an env var
        "BAZEL_COPTS",
        "BAZEL_CONLYOPTS",
        "BAZEL_CXXOPTS",
        "BAZEL_LINKOPTS",
    ],
    implementation = _apple_cc_autoconf_impl,
    configure = True,
)
