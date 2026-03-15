load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")

def negatable_feature(
        *,
        name,
        actions,
        args,
        **kwargs):
    args_name = "_{}_args".format(name)
    cc_feature(
        name = name,
        feature_name = name,
        args = [
            ":" + args_name,
        ],
    )

    cc_args(
        name = args_name,
        actions = actions,
        args = args,
        **kwargs
    )

def enableable_feature(
        *,
        name,
        actions = [],
        args = [],
        custom_args = [],
        overrides = None,
        **kwargs):
    cc_feature(
        name = name,
        feature_name = None if overrides else name,
        overrides = overrides,
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
