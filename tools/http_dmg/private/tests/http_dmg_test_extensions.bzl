"""Bzlmod module extensions that are only used for tests"""

load(":http_dmg_test_deps.bzl", "http_dmg_test_deps")

def _http_dmg_test_impl(module_ctx):
    # type: (module_ctx) -> extension_metadata
    # TODO(https://github.com/bazelbuild/bazel/issues/32020): make this an
    # annotation when supported Bazel versions expose context and metadata types.
    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = [],
        root_module_direct_dev_deps = http_dmg_test_deps(),
    )

http_dmg_test = module_extension(
    doc = "A test module for `http_dmg`.",
    implementation = _http_dmg_test_impl,
)
