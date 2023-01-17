"""Configure the Apple CC toolchain"""

load("//crosstool:osx_cc_configure.bzl", "configure_osx_toolchain")

_DISABLE_ENV_VAR = "BAZEL_NO_APPLE_CPP_TOOLCHAIN"

def _apple_cc_autoconf_toolchains_impl(repository_ctx):
    """Generate BUILD file with 'toolchain' targets for the local host C++ toolchain.

    Args:
      repository_ctx: repository context
    """
    env = repository_ctx.os.environ
    should_disable = _DISABLE_ENV_VAR in env and env[_DISABLE_ENV_VAR] == "1"

    if should_disable:
        repository_ctx.file("BUILD", "# Apple CC toolchain autoconfiguration was disabled by {} env variable.".format(_DISABLE_ENV_VAR))
    elif repository_ctx.os.name.startswith("mac os"):
        repository_ctx.symlink(
            repository_ctx.path(Label("@build_bazel_apple_support//crosstool:BUILD.toolchains")),
            "BUILD",
        )
    else:
        repository_ctx.file("BUILD", "# Apple CC toolchain autoconfiguration was disabled because you're not running on macOS")

_apple_cc_autoconf_toolchains = repository_rule(
    environ = [_DISABLE_ENV_VAR],
    implementation = _apple_cc_autoconf_toolchains_impl,
    configure = True,
)

def _apple_cc_autoconf_impl(repository_ctx):
    env = repository_ctx.os.environ
    should_disable = _DISABLE_ENV_VAR in env and env[_DISABLE_ENV_VAR] == "1"

    if should_disable:
        repository_ctx.file("BUILD", "# Apple CC autoconfiguration was disabled by {} env variable.".format(_DISABLE_ENV_VAR))
    elif repository_ctx.os.name.startswith("mac os"):
        if not configure_osx_toolchain(repository_ctx):
            fail("Failed to configure Apple CC toolchain, if you only have the command line tools installed and not Xcode, you cannot use this toolchain. You should either remove it or temporarily set '{}=1' in the environment".format(_DISABLE_ENV_VAR))
    else:
        repository_ctx.file("BUILD", "# Apple CC autoconfiguration was disabled because you're not on macOS")

MSVC_ENVVARS = [
    "BAZEL_VC",
    "BAZEL_VC_FULL_VERSION",
    "BAZEL_VS",
    "BAZEL_WINSDK_FULL_VERSION",
    "VS90COMNTOOLS",
    "VS100COMNTOOLS",
    "VS110COMNTOOLS",
    "VS120COMNTOOLS",
    "VS140COMNTOOLS",
    "VS150COMNTOOLS",
    "VS160COMNTOOLS",
    "TMP",
    "TEMP",
]

_apple_cc_autoconf = repository_rule(
    environ = [
        _DISABLE_ENV_VAR,
        "ABI_LIBC_VERSION",
        "ABI_VERSION",
        "BAZEL_COMPILER",
        "BAZEL_HOST_SYSTEM",
        "BAZEL_CXXOPTS",
        "BAZEL_LINKOPTS",
        "BAZEL_LINKLIBS",
        "BAZEL_LLVM_COV",
        "BAZEL_LLVM_PROFDATA",
        "BAZEL_PYTHON",
        "BAZEL_SH",
        "BAZEL_TARGET_CPU",
        "BAZEL_TARGET_LIBC",
        "BAZEL_TARGET_SYSTEM",
        "BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN",
        "BAZEL_USE_LLVM_NATIVE_COVERAGE",
        "BAZEL_LLVM",
        "BAZEL_IGNORE_SYSTEM_HEADERS_VERSIONS",
        "USE_CLANG_CL",
        "CC",
        "CC_CONFIGURE_DEBUG",
        "CC_TOOLCHAIN_NAME",
        "CPLUS_INCLUDE_PATH",
        "DEVELOPER_DIR",
        "GCOV",
        "HOMEBREW_RUBY_PATH",
        "SYSTEMROOT",
        "USER",
    ] + MSVC_ENVVARS,
    implementation = _apple_cc_autoconf_impl,
    configure = True,
)

# buildifier: disable=unnamed-macro
def apple_cc_configure():
    _apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")
    _apple_cc_autoconf(name = "local_config_apple_cc")
    native.register_toolchains(
        # Use register_toolchain's target pattern expansion to register all toolchains in the package.
        "@local_config_apple_cc_toolchains//:all",
    )

def _apple_cc_configure_extension_impl(_):
    _apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")
    _apple_cc_autoconf(name = "local_config_apple_cc")

apple_cc_configure_extension = module_extension(implementation = _apple_cc_configure_extension_impl)
