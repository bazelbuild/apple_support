"""Configure the Apple CC toolchain"""

load("//crosstool/internal:setup.bzl", "apple_cc_autoconf", "apple_cc_autoconf_toolchains")

# buildifier: disable=unnamed-macro
def apple_cc_configure():
    apple_cc_autoconf_toolchains(name = "local_config_apple_cc_toolchains")
    apple_cc_autoconf(name = "local_config_apple_cc")
    native.register_toolchains(
        # Use register_toolchain's target pattern expansion to register all toolchains in the package.
        "@local_config_apple_cc_toolchains//:all",
    )
