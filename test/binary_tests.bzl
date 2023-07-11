"""Tests verifying produced binaries"""

load(
    "//test/rules:apple_verification_test.bzl",
    "apple_verification_test",
)

def binary_test_suite(name):
    apple_verification_test(
        name = "{}_macos_binary_test".format(name),
        tags = [name],
        build_type = "device",
        cpus = {"macos_cpus": "x86_64"},
        expected_platform_type = "macos",
        verifier_script = "//test/shell:verify_binary.sh",
        target_under_test = "//test/test_data:apple_binary",
    )
