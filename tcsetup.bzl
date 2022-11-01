"""TODO"""

load("@bazel_tools//tools/cpp:cc_configure.bzl", "cc_autoconf_impl")
load("//crosstool:osx_cc_configure.bzl", "configure_osx_toolchain")

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

_apple_cc_autoconf_toolchains = repository_rule(
    environ = [
        "BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN",
        "BAZEL_USE_CPP_ONLY_TOOLCHAIN",
    ],
    implementation = _impl,
    configure = True,
)

def _apple_cc_autoconf_impl(repository_ctx):
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
        if not configure_osx_toolchain(repository_ctx):
            cc_autoconf_impl(repository_ctx, {})
    else:
        cc_autoconf_impl(repository_ctx, {})

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
    _apple_cc_autoconf(name = "local_config_cc")
    native.register_toolchains(
        # Use register_toolchain's target pattern expansion to register all toolchains in the package.
        "@local_config_apple_cc_toolchains//:all",
    )
