"""Helpers for common rules based toolchain patterns."""

load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")

visibility("//...")

def negatable_feature(
        *,
        name,
        actions = [],
        overrides = None,
        args = None,
        env = None,
        custom_args = [],
        visibility = None,
        **kwargs):
    """Defines a feature that can be enabled or disabled by the user.

    Args:
        name: The name of the feature (this is what would be used with `--features=-NAME`)
        actions: The actions that this feature applies to. Ignored if custom_args is provided.
        overrides: The upstream feature that this feature overrides.
        args: The args to apply when this feature is enabled. Ignored if custom_args is provided.
        env: The env variables to apply when this feature is enabled. Ignored if custom_args is provided.
        custom_args: A list of custom args targets to apply when this feature is enabled.
        visibility: The visibility of the generated targets.
        **kwargs: Additional arguments to pass to cc_args when generating the args target. Ignored if custom_args is provided.
    """

    all_args = []
    if custom_args:
        if actions or args or env or kwargs:
            fail("negatable_feature cannot have both custom_args and actions/args/env/kwargs")

        all_args = custom_args
    else:
        if not actions or (not args and not env):
            fail("negatable_feature must have either custom_args or both actions and args|env")
        args_name = "_{}_args".format(name)
        all_args.append(":" + args_name)
        cc_args(
            name = args_name,
            actions = actions,
            args = args,
            env = env,
            visibility = visibility,
            **kwargs
        )

    cc_feature(
        name = name,
        feature_name = None if overrides else name,
        overrides = overrides,
        args = all_args,
        visibility = visibility,
    )

def enableable_feature(
        *,
        name,
        actions = [],
        args = [],
        custom_args = [],
        overrides = None,
        mutually_exclusive = None,
        requires_any_of = [],
        **kwargs):
    """Defines a feature that can be enabled by the user.

    This produces multiple underlying `cc_feature` targets. The `NAME_wrapper` target must be
    added in the `enabled_features` of the toolchain in the order you would like the arguments
    to be applied. The `NAME` feature must be added to the `known_arguments` of the toolchain.
    If you don't care about argument ordering, don't use this macro.

    Args:
        name: The name of the feature (this is what would be used with `--features=NAME`)
        actions: The actions that this feature applies to. Ignored if custom_args is provided.
        args: The args to apply when this feature is enabled. Ignored if custom_args is provided.
        custom_args: A list of custom args targets to apply when this feature is enabled.
        overrides: The upstream feature that this feature overrides.
        mutually_exclusive: A list of features that cannot be enabled at the same time as this one.
        requires_any_of: A list of features where at least one must be enabled when this feature is enabled.
        **kwargs: Additional arguments to pass to cc_args when generating the args target. Ignored if custom_args is provided.
    """

    cc_feature(
        name = name,
        feature_name = None if overrides else name,
        overrides = overrides,
        mutually_exclusive = mutually_exclusive,
        requires_any_of = requires_any_of,
    )

    all_args = []
    if custom_args:
        if actions or args or kwargs:
            fail("enableable_feature cannot have both custom_args and actions/args/kwargs")

        all_args = custom_args
    else:
        if not actions or not args:
            fail("enableable_feature must have either custom_args or both actions and args")
        args_name = "_{}_args".format(name)
        all_args = [":" + args_name]
        cc_args(
            name = args_name,
            actions = actions,
            args = args,
            **kwargs
        )

    cc_feature(
        name = name + "_wrapper",
        feature_name = "__" + name + "_wrapper",
        args = all_args,
        requires_any_of = [":" + name],
    )
