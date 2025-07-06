"""Configure the Apple CC toolchain"""

load("@bazel_features//:features.bzl", "bazel_features")
load(":setup_internal.bzl", "apple_cc_autoconf", "apple_cc_autoconf_toolchains")

def _apple_cc_configure_extension_impl(module_ctx):
    apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")
    apple_cc_autoconf(name = "local_config_apple_cc")
    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(reproducible = True)
    else:
        return None

apple_cc_configure_extension = module_extension(implementation = _apple_cc_configure_extension_impl)
