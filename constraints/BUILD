# Standard constraint_settings and constraint_values for items common to rules_swift and rules_apple.

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

filegroup(
    name = "srcs",
    srcs = ["BUILD"],
)

# Constraint indicating the target environment (e.g. device, simulator).
constraint_setting(
    name = "target_environment",
    visibility = ["//visibility:private"],
)

constraint_value(
    name = "device",
    constraint_setting = ":target_environment",
)

constraint_value(
    name = "simulator",
    constraint_setting = ":target_environment",
)

constraint_value(
    name = "catalyst",
    constraint_setting = ":target_environment",
)
