load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")

def negatable_feature(
        *,
        name,
        actions = [],
        overrides = None,
        args = [],
        env = {},
        custom_args = [],
        **kwargs):
    all_args = []
    if custom_args:
        all_args = custom_args
    else:
        if not actions or (not args and not env):
            fail("negatable_feature must have either custom_args or both actions and args|env") # FIXME: improve
        args_name = "_{}_args".format(name)
        all_args.append(":" + args_name)
        cc_args(
            name = args_name,
            actions = actions,
            args = args,
            env = env,
            **kwargs
        )

    cc_feature(
        name = name,
        feature_name = None if overrides else name,
        overrides = overrides,
        args = all_args,
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
    cc_feature(
        name = name,
        feature_name = None if overrides else name,
        overrides = overrides,
        mutually_exclusive = mutually_exclusive,
        requires_any_of = requires_any_of,
    )

    all_args = []
    if custom_args:
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
