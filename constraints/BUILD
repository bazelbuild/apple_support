# Standard constraint_settings and constraint_values for items common to rules_swift and rules_apple.

package(
    default_visibility = ["//visibility:public"],
)

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

# Constraint indicating if the platform belongs to an "Apple" platform (iOS, watchOS, tvOS, etc.)
constraint_setting(
    name = "target_vendor",
    visibility = ["//visibility:private"],
)

constraint_value(
    name = "apple",
    constraint_setting = ":target_vendor",
)

# A constraint to indicate whether the platform supports Apple's pointer
# authentication.
constraint_setting(
    name = "pointer_authentication_setting",
    visibility = ["//visibility:private"],
)

# If a platform has this constraint_value, it supports Apple's pointer
# authentication.
constraint_value(
    name = "pointer_authentication",
    constraint_setting = ":pointer_authentication_setting",
)
