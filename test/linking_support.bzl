"""Linking logic copied from rules_apple"""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

TargetTripletInfo = provider(
    "Contains the target triplet (architecture, platform, environment) for a given configuration.",
    fields = {
        "architecture": "string, the CPU as returned by AppleConfiguration.getSingleArchitecture()",
        "platform": "apple_platform.PLATFORM_TYPE string as returned by apple_platform.get_target_platform()",
        "environment": "string ('device', 'simulator' or 'macabi) as returned by apple_platform.get_target_environment",
    },
)

def _get_target_triplet(config):
    """Returns the target triplet (architecture, platform, environment) for a given configuration."""
    cpu_platform = apple_common.apple_platform.for_target_cpu(apple_common.get_cpu(config))
    apple_config = apple_common.get_apple_config(config)

    return TargetTripletInfo(
        architecture = apple_config.single_arch_cpu,
        platform = apple_common.apple_platform.get_target_platform(cpu_platform),
        environment = apple_common.apple_platform.get_target_environment(cpu_platform),
    )

def _build_avoid_library_set(avoid_dep_linking_contexts):
    avoid_library_set = dict()
    for linking_context in avoid_dep_linking_contexts:
        for linker_input in linking_context.linker_inputs.to_list():
            for library_to_link in linker_input.libraries:
                library_artifact = apple_common.compilation_support.get_static_library_for_linking(library_to_link)
                if library_artifact:
                    avoid_library_set[library_artifact.short_path] = True
    return avoid_library_set

def _get_split_target_triplet(ctx):
    result = dict()
    ctads = apple_common.get_split_prerequisites(ctx)
    for split_transition_key, config in ctads.items():
        if split_transition_key == None:
            fail("unexpected empty key in split transition")
        result[split_transition_key] = _get_target_triplet(config)
    return result

def _subtract_linking_contexts(owner, linking_contexts, avoid_dep_linking_contexts):
    libraries = []
    user_link_flags = []
    additional_inputs = []
    linkstamps = []
    avoid_library_set = _build_avoid_library_set(avoid_dep_linking_contexts)
    for linking_context in linking_contexts:
        for linker_input in linking_context.linker_inputs.to_list():
            for library_to_link in linker_input.libraries:
                library_artifact = apple_common.compilation_support.get_library_for_linking(library_to_link)
                if library_artifact.short_path not in avoid_library_set:
                    libraries.append(library_to_link)
            user_link_flags.extend(linker_input.user_link_flags)
            additional_inputs.extend(linker_input.additional_inputs)
            linkstamps.extend(linker_input.linkstamps)
    linker_input = cc_common.create_linker_input(
        owner = owner,
        libraries = depset(libraries, order = "topological"),
        user_link_flags = user_link_flags,
        additional_inputs = depset(additional_inputs),
        linkstamps = depset(linkstamps),
    )
    return cc_common.create_linking_context(
        linker_inputs = depset([linker_input]),
        owner = owner,
    )

def link_multi_arch_binary(*, ctx, stamp = -1):
    """Copied from rules_apple.

    Args:
        ctx: rule ctx
        stamp: See upstream docs

    Returns:
        struct of linking info
    """

    # TODO: Delete when we drop bazel 7.x
    legacy_linking_function = getattr(apple_common, "link_multi_arch_binary", None)
    if legacy_linking_function:
        return legacy_linking_function(ctx = ctx, stamp = stamp)

    split_target_triplets = _get_split_target_triplet(ctx)
    split_build_configs = apple_common.get_split_build_configs(ctx)
    split_deps = ctx.split_attr.deps
    child_configs_and_toolchains = ctx.split_attr._child_configuration_dummy

    if split_deps and split_deps.keys() != child_configs_and_toolchains.keys():
        fail(("Split transition keys are different between 'deps' [%s] and " +
              "'_child_configuration_dummy' [%s]") % (
            split_deps.keys(),
            child_configs_and_toolchains.keys(),
        ))

    outputs = []
    cc_infos = []
    legacy_debug_outputs = {}

    # $(location...) is only used in one test, and tokenize only affects linkopts in one target
    additional_linker_inputs = getattr(ctx.attr, "additional_linker_inputs", [])
    attr_linkopts = [
        ctx.expand_location(opt, targets = additional_linker_inputs)
        for opt in getattr(ctx.attr, "linkopts", [])
    ]
    attr_linkopts = [token for opt in attr_linkopts for token in ctx.tokenize(opt)]

    for split_transition_key, child_toolchain in child_configs_and_toolchains.items():
        cc_toolchain = child_toolchain[cc_common.CcToolchainInfo]
        deps = split_deps.get(split_transition_key, [])
        target_triplet = split_target_triplets.get(split_transition_key)

        common_variables = apple_common.compilation_support.build_common_variables(
            ctx = ctx,
            toolchain = cc_toolchain,
            deps = deps,
            attr_linkopts = attr_linkopts,
        )

        cc_infos.append(CcInfo(
            compilation_context = cc_common.merge_compilation_contexts(
                compilation_contexts =
                    common_variables.objc_compilation_context.cc_compilation_contexts,
            ),
            linking_context = cc_common.merge_linking_contexts(
                linking_contexts = common_variables.objc_linking_context.cc_linking_contexts,
            ),
        ))

        cc_linking_context = _subtract_linking_contexts(
            owner = ctx.label,
            linking_contexts = common_variables.objc_linking_context.cc_linking_contexts,
            avoid_dep_linking_contexts = [],
        )

        child_config = split_build_configs.get(split_transition_key)

        additional_outputs = []
        extensions = {}

        dsym_binary = None
        if ctx.fragments.cpp.apple_generate_dsym:
            if ctx.fragments.cpp.objc_should_strip_binary:
                suffix = "_bin_unstripped.dwarf"
            else:
                suffix = "_bin.dwarf"
            dsym_binary = ctx.actions.declare_shareable_artifact(
                ctx.label.package + "/" + ctx.label.name + suffix,
                child_config.bin_dir,
            )
            extensions["dsym_path"] = dsym_binary.path  # dsym symbol file
            additional_outputs.append(dsym_binary)
            legacy_debug_outputs.setdefault(target_triplet.architecture, {})["dsym_binary"] = dsym_binary

        linkmap = None
        if ctx.fragments.cpp.objc_generate_linkmap:
            linkmap = ctx.actions.declare_shareable_artifact(
                ctx.label.package + "/" + ctx.label.name + ".linkmap",
                child_config.bin_dir,
            )
            extensions["linkmap_exec_path"] = linkmap.path  # linkmap file
            additional_outputs.append(linkmap)
            legacy_debug_outputs.setdefault(target_triplet.architecture, {})["linkmap"] = linkmap

        name = ctx.label.name + "_bin"
        executable = apple_common.compilation_support.register_configuration_specific_link_actions(
            name = name,
            common_variables = common_variables,
            cc_linking_context = cc_linking_context,
            build_config = child_config,
            stamp = stamp,
            user_variable_extensions = extensions,
            additional_outputs = additional_outputs,
            deps = deps,
            attr_linkopts = attr_linkopts,
            extra_link_args = [],
            extra_link_inputs = [],
        )

        output = {
            "binary": executable,
            "platform": target_triplet.platform,
            "architecture": target_triplet.architecture,
            "environment": target_triplet.environment,
            "dsym_binary": dsym_binary,
            "linkmap": linkmap,
        }

        outputs.append(struct(**output))

    header_tokens = []
    for _, deps in split_deps.items():
        for dep in deps:
            if CcInfo in dep:
                header_tokens.append(dep[CcInfo].compilation_context.validation_artifacts)

    output_groups = {"_validation": depset(transitive = header_tokens)}

    return struct(
        cc_info = cc_common.merge_cc_infos(direct_cc_infos = cc_infos),
        output_groups = output_groups,
        outputs = outputs,
    )

def link_multi_arch_static_library(ctx):
    """Copied from rules_apple.

    Args:
        ctx: rule ctx

    Returns:
        struct of linking info
    """

    # TODO: Delete when we drop bazel 7.x
    legacy_linking_function = getattr(apple_common, "link_multi_arch_static_library", None)
    if legacy_linking_function:
        return legacy_linking_function(ctx = ctx)

    split_target_triplets = _get_split_target_triplet(ctx)

    split_deps = ctx.split_attr.deps
    split_avoid_deps = ctx.split_attr.avoid_deps
    child_configs_and_toolchains = ctx.split_attr._child_configuration_dummy

    outputs = []

    for split_transition_key, child_toolchain in child_configs_and_toolchains.items():
        cc_toolchain = child_toolchain[cc_common.CcToolchainInfo]
        common_variables = apple_common.compilation_support.build_common_variables(
            ctx = ctx,
            toolchain = cc_toolchain,
            use_pch = True,
            deps = split_deps[split_transition_key],
        )

        avoid_objc_providers = []
        avoid_cc_providers = []
        avoid_cc_linking_contexts = []

        if len(split_avoid_deps.keys()):
            for dep in split_avoid_deps[split_transition_key]:
                if apple_common.Objc in dep:
                    avoid_objc_providers.append(dep[apple_common.Objc])
                if CcInfo in dep:
                    avoid_cc_providers.append(dep[CcInfo])
                    avoid_cc_linking_contexts.append(dep[CcInfo].linking_context)

        name = ctx.label.name + "-" + cc_toolchain.target_gnu_system_name + "-fl"

        cc_linking_context = _subtract_linking_contexts(
            owner = ctx.label,
            linking_contexts = common_variables.objc_linking_context.cc_linking_contexts,
            avoid_dep_linking_contexts = avoid_cc_linking_contexts,
        )
        linking_outputs = apple_common.compilation_support.register_fully_link_action(
            name = name,
            common_variables = common_variables,
            cc_linking_context = cc_linking_context,
        )

        output = {
            "library": linking_outputs.library_to_link.static_library,
        }

        if split_target_triplets != None:
            target_triplet = split_target_triplets.get(split_transition_key)
            output["platform"] = target_triplet.platform
            output["architecture"] = target_triplet.architecture
            output["environment"] = target_triplet.environment

        outputs.append(struct(**output))

    header_tokens = []
    for _, deps in split_deps.items():
        for dep in deps:
            if CcInfo in dep:
                header_tokens.append(dep[CcInfo].compilation_context.validation_artifacts)

    output_groups = {"_validation": depset(transitive = header_tokens)}

    return struct(
        outputs = outputs,
        output_groups = OutputGroupInfo(**output_groups),
    )
