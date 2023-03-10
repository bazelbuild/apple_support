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
        success, error = configure_osx_toolchain(
            repository_ctx = repository_ctx,
            alternate_linker_path = repository_ctx.attr.alternate_linker_path,
            alternate_linker_args = repository_ctx.attr.alternate_linker_args,
            default_linker_args = repository_ctx.attr.default_linker_args,
        )
        if not success:
            fail("Failed to configure Apple CC toolchain, if you only have the command line tools installed and not Xcode, you cannot use this toolchain. You should either remove it or temporarily set '{}=1' in the environment: {}".format(_DISABLE_ENV_VAR, error))
    else:
        repository_ctx.file("BUILD", "# Apple CC autoconfiguration was disabled because you're not on macOS")

_apple_cc_autoconf = repository_rule(
    environ = [
        _DISABLE_ENV_VAR,
        "USE_CLANG_CL",  # Kept as a hack for those who rely on this invaliding the toolchain
        "DEVELOPER_DIR",  # Used for making sure we use the right Xcode for compiling toolchain binaries
        "GCOV",  # TODO: Remove this
        "USER",  # Used to allow paths for custom toolchains to be used by C* compiles
    ],
    implementation = _apple_cc_autoconf_impl,
    configure = True,
    attrs = {
        "alternate_linker_path": attr.label(allow_single_file = True),
        "alternate_linker_args": attr.string_list(),
        "default_linker_args": attr.string_list(),
    },
)

# buildifier: disable=unnamed-macro
def apple_cc_configure():
    _apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")
    _apple_cc_autoconf(name = "local_config_apple_cc")
    native.register_toolchains(
        # Use register_toolchain's target pattern expansion to register all toolchains in the package.
        "@local_config_apple_cc_toolchains//:all",
    )

def _apple_cc_configure_extension_impl(module_ctx):
    _apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")

    root_modules = [m for m in module_ctx.modules if m.is_root and m.tags.setup]
    if len(root_modules) > 1:
        fail("Expected at most one root module, found {}".format(", ".join([x.name for x in root_modules])))

    if root_modules:
        root_module = root_modules[0]
    else:
        root_module = module_ctx.modules[0]

    kwargs = {}
    if root_module.tags.setup:
        kwargs["alternate_linker_path"] = root_module.tags.setup[0].alternate_linker_path
        kwargs["alternate_linker_args"] = root_module.tags.setup[0].alternate_linker_args
        kwargs["default_linker_args"] = root_module.tags.setup[0].default_linker_args

    _apple_cc_autoconf(
        name = "local_config_apple_cc",
        **kwargs
    )

apple_cc_configure_extension = module_extension(
    implementation = _apple_cc_configure_extension_impl,
    tag_classes = {
        "setup": tag_class(attrs = {
            "alternate_linker_path": attr.label(allow_single_file = True),
            "alternate_linker_args": attr.string_list(),
            "default_linker_args": attr.string_list(),
        }),
    },
)
