"""Bzlmod module extensions that are only used for tests"""

load(":http_dmg_test_deps.bzl", "http_dmg_test_deps")

def _http_dmg_test_impl(module_ctx):
    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = [],
        root_module_direct_dev_deps = http_dmg_test_deps(),
    )

http_dmg_test = module_extension(
    doc = "A test module for `http_dmg`.",
    implementation = _http_dmg_test_impl,
)
