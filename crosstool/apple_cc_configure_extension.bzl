"""Extension configuring the C++ toolchain on macOS."""

load("@bazel_skylib//lib:modules.bzl", "modules")
load(":setup.bzl", "apple_cc_autoconf", "apple_cc_autoconf_toolchains")

def _apple_cc_configure_extension_impl():
    apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")
    apple_cc_autoconf(name = "local_config_apple_cc")

apple_cc_configure_extension = modules.as_extension(_apple_cc_configure_extension_impl)
