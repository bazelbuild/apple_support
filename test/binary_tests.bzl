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
        target_under_test = "//test/test_data:macos_binary",
    )

    apple_verification_test(
        name = "{}_visionos_device_test".format(name),
        tags = [name],
        build_type = "device",
        cpus = {"visionos_cpus": "arm64"},
        expected_platform_type = "visionos",
        verifier_script = "//test/shell:verify_binary.sh",
        target_under_test = "//test/test_data:visionos_binary",
    )

    apple_verification_test(
        name = "{}_visionos_arm64_simulator_test".format(name),
        tags = [name],
        build_type = "simulator",
        cpus = {"visionos_cpus": "sim_arm64"},
        expected_platform_type = "visionos",
        verifier_script = "//test/shell:verify_binary.sh",
        target_under_test = "//test/test_data:visionos_binary",
    )

    apple_verification_test(
        name = "{}_visionos_x86_64_simulator_test".format(name),
        tags = [name],
        build_type = "simulator",
        cpus = {"visionos_cpus": "x86_64"},
        expected_platform_type = "visionos",
        verifier_script = "//test/shell:verify_binary.sh",
        target_under_test = "//test/test_data:visionos_binary",
    )

    apple_verification_test(
        name = "{}_unused_symbol_is_kept_by_default".format(name),
        build_type = "simulator",
        cpus = {"ios_multi_cpus": "x86_64"},
        compilation_mode = "fastbuild",
        objc_enable_binary_stripping = False,
        verifier_script = "//test:verify_unused_symbol_exists.sh",
        target_under_test = "//test/test_data:ios_app_with_unused_symbol",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_unused_symbol_is_stripped".format(name),
        build_type = "simulator",
        cpus = {"ios_multi_cpus": "x86_64"},
        compilation_mode = "opt",
        objc_enable_binary_stripping = True,
        verifier_script = "//test:verify_stripped_symbols.sh",
        target_under_test = "//test/test_data:ios_app_with_unused_symbol",
        tags = [name],
    )
