"""Linking logic copied from rules_apple"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_cc//cc/common:objc_info.bzl", "ObjcInfo")
load("@rules_cc//cc/private/rules_impl:objc_compilation_support.bzl", "compilation_support")  # buildifier: disable=bzl-visibility
load(":cc_toolchain_forwarder.bzl", "CcWrapperInfo", "TestApplePlatformInfo")

def _build_avoid_library_set(avoid_dep_linking_contexts):
    avoid_library_set = dict()
    for linking_context in avoid_dep_linking_contexts:
        for linker_input in linking_context.linker_inputs.to_list():
            for library_to_link in linker_input.libraries:
                library_artifact = compilation_support.get_static_library_for_linking(library_to_link)
                if library_artifact:
                    avoid_library_set[library_artifact.short_path] = True
    return avoid_library_set

def _subtract_linking_contexts(owner, linking_contexts, avoid_dep_linking_contexts):
    libraries = []
    user_link_flags = []
    additional_inputs = []
    linkstamps = []
    avoid_library_set = _build_avoid_library_set(avoid_dep_linking_contexts)
    for linking_context in linking_contexts:
        for linker_input in linking_context.linker_inputs.to_list():
            for library_to_link in linker_input.libraries:
                library_artifact = _get_library_for_linking(library_to_link)
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
    )

def _get_library_for_linking(library_to_link):
    if library_to_link.static_library:
        return library_to_link.static_library
    elif library_to_link.pic_static_library:
        return library_to_link.pic_static_library
    elif library_to_link.interface_library:
        return library_to_link.interface_library
    else:
        return library_to_link.dynamic_library

def _get_libraries_for_linking(libraries_to_link):
    libraries = []
    for library_to_link in libraries_to_link:
        libraries.append(_get_library_for_linking(library_to_link))
    return libraries

def _libraries_from_linking_context(linking_context):
    libraries = []
    for linker_input in linking_context.linker_inputs.to_list():
        libraries.extend(linker_input.libraries)
    return depset(libraries, order = "topological")

def _classify_libraries(libraries_to_link):
    always_link_libraries = {
        lib: None
        for lib in _get_libraries_for_linking(
            [lib for lib in libraries_to_link if lib.alwayslink],
        )
    }
    as_needed_libraries = {
        lib: None
        for lib in _get_libraries_for_linking(
            [lib for lib in libraries_to_link if not lib.alwayslink],
        )
        if lib not in always_link_libraries
    }
    return always_link_libraries.keys(), as_needed_libraries.keys()

def _linkstamp_map(ctx, linkstamps, output, build_config):
    # create linkstamps_map - mapping from linkstamps to object files
    linkstamps_map = {}

    stamp_output_dir = paths.join(ctx.label.package, "_objs", output.basename)
    for linkstamp in linkstamps:
        linkstamp_file = linkstamp.file()
        stamp_output_path = paths.join(
            stamp_output_dir,
            linkstamp_file.short_path[:-len(linkstamp_file.extension)].rstrip(".") + ".o",
        )
        stamp_output_file = ctx.actions.declare_shareable_artifact(
            stamp_output_path,
            build_config.bin_dir,
        )
        linkstamps_map[linkstamp_file] = stamp_output_file
    return linkstamps_map

def _dedup_link_flags(flags, seen_flags = {}):
    new_flags = []
    previous_arg = None
    for arg in flags:
        if previous_arg in ["-framework", "-weak_framework"]:
            framework = arg
            key = previous_arg[1] + framework
            if key not in seen_flags:
                new_flags.extend([previous_arg, framework])
                seen_flags[key] = True
            previous_arg = None
        elif arg in ["-framework", "-weak_framework"]:
            previous_arg = arg
        elif arg.startswith("-Wl,-framework,") or arg.startswith("-Wl,-weak_framework,"):
            framework = arg.split(",")[2]
            key = arg[5] + framework
            if key not in seen_flags:
                new_flags.extend([arg.split(",")[1], framework])
                seen_flags[key] = True
        elif arg.startswith("-Wl,-rpath,"):
            rpath = arg.split(",")[2]
            key = arg[5] + rpath
            if key not in seen_flags:
                new_flags.append(arg)
                seen_flags[key] = True
        elif arg.startswith("-l"):
            if arg not in seen_flags:
                new_flags.append(arg)
                seen_flags[arg] = True
        else:
            new_flags.append(arg)

    same = (
        len(flags) == len(new_flags) and
        all([flags[i] == new_flags[i] for i in range(0, len(flags))])
    )

    return (same, new_flags, seen_flags)

def _register_obj_filelist_action(ctx, build_config, obj_files):
    obj_list = ctx.actions.declare_shareable_artifact(
        paths.join(ctx.label.package, ctx.label.name + "-linker.objlist"),
        build_config.bin_dir,
    )

    args = ctx.actions.args()
    args.add_all(obj_files)
    args.set_param_file_format("multiline")
    ctx.actions.write(obj_list, args)

    return obj_list

def _create_deduped_linkopts_list(linker_inputs):
    seen_flags = {}
    final_linkopts = []
    for linker_input in linker_inputs.to_list():
        (_, new_flags, seen_flags) = _dedup_link_flags(
            linker_input.user_link_flags,
            seen_flags,
        )
        final_linkopts.extend(new_flags)

    return final_linkopts

def _emit_builtin_objc_strip_action(ctx):
    return (
        ctx.fragments.objc.builtin_objc_strip_action and
        ctx.fragments.cpp.objc_enable_binary_stripping() and
        ctx.fragments.cpp.compilation_mode() == "opt"
    )

def _apple_common_platform_from_platform_info(*, apple_platform_info):
    if apple_platform_info.target_os == "ios":
        if apple_platform_info.target_environment == "device":
            return apple_common.platform.ios_device
        elif apple_platform_info.target_environment == "simulator":
            return apple_common.platform.ios_simulator
    elif apple_platform_info.target_os == "macos":
        return apple_common.platform.macos
    elif apple_platform_info.target_os == "tvos":
        if apple_platform_info.target_environment == "device":
            return apple_common.platform.tvos_device
        elif apple_platform_info.target_environment == "simulator":
            return apple_common.platform.tvos_simulator
    elif apple_platform_info.target_os == "visionos":
        if apple_platform_info.target_environment == "device":
            return apple_common.platform.visionos_device
        elif apple_platform_info.target_environment == "simulator":
            return apple_common.platform.visionos_simulator
    elif apple_platform_info.target_os == "watchos":
        if apple_platform_info.target_environment == "device":
            return apple_common.platform.watchos_device
        elif apple_platform_info.target_environment == "simulator":
            return apple_common.platform.watchos_simulator

    fail("Internal Error: Found unrecognized target os of " + apple_platform_info.target_os)

def _register_binary_strip_action(
        ctx,
        name,
        binary,
        feature_configuration,
        apple_platform_info,
        extra_link_args):
    strip_safe = ctx.fragments.objc.strip_executable_safely

    # For dylibs, loadable bundles, and kexts, must strip only local symbols.
    link_dylib = cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "link_dylib",
    )
    link_bundle = cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "link_bundle",
    )
    if ("-dynamiclib" in extra_link_args or link_dylib or
        "-bundle" in extra_link_args or link_bundle or "-kext" in extra_link_args):
        strip_safe = True

    stripped_binary = ctx.actions.declare_shareable_artifact(
        paths.join(ctx.label.package, name),
        apple_platform_info.target_build_config.bin_dir,
    )
    args = ctx.actions.args()
    args.add("strip")
    if strip_safe:
        args.add("-x")
    args.add("-o", stripped_binary)
    args.add(binary)
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    platform = _apple_common_platform_from_platform_info(apple_platform_info = apple_platform_info)

    ctx.actions.run(
        mnemonic = "ObjcBinarySymbolStrip",
        executable = "/usr/bin/xcrun",
        arguments = [args],
        inputs = [binary],
        outputs = [stripped_binary],
        execution_requirements = ctx.attr._xcode_config[apple_common.XcodeVersionConfig].execution_info(),
        env = apple_common.apple_host_system_env(xcode_config) |
              apple_common.target_apple_env(xcode_config, platform),
    )
    return stripped_binary

def _create_deduped_linkopts_linking_context(cc_linking_context, seen_flags):
    linker_inputs = []
    for linker_input in cc_linking_context.linker_inputs.to_list():
        (same, new_flags, seen_flags) = _dedup_link_flags(
            linker_input.user_link_flags,
            seen_flags,
        )
        if same:
            linker_inputs.append(linker_input)
        else:
            linker_inputs.append(cc_common.create_linker_input(
                owner = linker_input.owner,
                libraries = depset(linker_input.libraries),
                user_link_flags = new_flags,
                additional_inputs = depset(linker_input.additional_inputs),
                linkstamps = depset(linker_input.linkstamps),
            ))

    return (
        cc_common.create_linking_context(
            linker_inputs = depset(linker_inputs),
        ),
        seen_flags,
    )

def _register_configuration_specific_link_actions_with_cpp_variables(
        name,
        binary,
        common_variables,
        feature_configuration,
        cc_linking_context,
        apple_platform_info,
        extra_link_args,
        stamp,
        user_variable_extensions,
        additional_outputs,
        extra_link_inputs,
        attr_linkopts):
    ctx = common_variables.ctx

    prefixed_attr_linkopts = [
        "-Wl,%s" % linkopt
        for linkopt in attr_linkopts
    ]

    seen_flags = {}
    (_, user_link_flags, seen_flags) = _dedup_link_flags(
        extra_link_args + prefixed_attr_linkopts,
        seen_flags,
    )
    (cc_linking_context, _) = _create_deduped_linkopts_linking_context(
        cc_linking_context,
        seen_flags,
    )

    cc_common.link(
        name = name,
        actions = ctx.actions,
        additional_inputs = (
            extra_link_inputs +
            getattr(ctx.files, "additional_linker_inputs", [])
        ),
        additional_outputs = additional_outputs,
        build_config = apple_platform_info.target_build_config,
        cc_toolchain = common_variables.toolchain,
        feature_configuration = feature_configuration,
        language = "objc",
        linking_contexts = [cc_linking_context],
        main_output = binary,
        output_type = "executable",
        stamp = stamp,
        user_link_flags = user_link_flags,
        variables_extension = user_variable_extensions,
    )

    if _emit_builtin_objc_strip_action(ctx):
        return _register_binary_strip_action(
            ctx,
            name,
            binary,
            feature_configuration,
            apple_platform_info,
            extra_link_args,
        )
    else:
        return binary

def _register_configuration_specific_link_actions_with_objc_variables(
        name,
        binary,
        common_variables,
        feature_configuration,
        cc_linking_context,
        apple_platform_info,
        extra_link_args,
        stamp,
        user_variable_extensions,
        additional_outputs,
        extra_link_inputs,
        attr_linkopts):
    ctx = common_variables.ctx
    libraries_to_link = _libraries_from_linking_context(cc_linking_context).to_list()
    always_link_libraries, as_needed_libraries = _classify_libraries(libraries_to_link)
    static_runtimes = common_variables.toolchain.static_runtime_lib(
        feature_configuration = feature_configuration,
    )

    linkstamps = [
        linkstamp
        for linker_input in cc_linking_context.linker_inputs.to_list()
        for linkstamp in linker_input.linkstamps
    ]
    linkstamp_map = _linkstamp_map(ctx, linkstamps, binary, apple_platform_info.target_build_config)
    input_file_list = _register_obj_filelist_action(
        ctx,
        apple_platform_info.target_build_config,
        as_needed_libraries + static_runtimes.to_list() + linkstamp_map.values(),
    )

    extensions = user_variable_extensions | {
        "framework_paths": [],
        "framework_names": [],
        "weak_framework_names": [],
        "library_names": [],
        "filelist": input_file_list.path,
        "linked_binary": binary.path,
        # artifacts to be passed to the linker with `-force_load`
        "force_load_exec_paths": [lib.path for lib in always_link_libraries],
        # linkopts from dependency
        "dep_linkopts": _create_deduped_linkopts_list(cc_linking_context.linker_inputs),
        "attr_linkopts": attr_linkopts,  # linkopts arising from rule attributes
    }
    additional_inputs = [
        input
        for linker_input in cc_linking_context.linker_inputs.to_list()
        for input in linker_input.additional_inputs
    ]
    cc_common.link(
        name = name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = common_variables.toolchain,
        language = "objc",
        additional_inputs = (
            as_needed_libraries + always_link_libraries + [input_file_list] + extra_link_inputs +
            additional_inputs +
            getattr(ctx.files, "additional_linker_inputs", [])
        ),
        linking_contexts = [cc_common.create_linking_context(linker_inputs = depset(
            [cc_common.create_linker_input(
                owner = ctx.label,
                linkstamps = depset(linkstamps),
            )],
        ))],
        output_type = "executable",
        build_config = apple_platform_info.target_build_config,
        user_link_flags = extra_link_args,
        stamp = stamp,
        variables_extension = extensions,
        additional_outputs = additional_outputs,
        main_output = binary,
    )

    if _emit_builtin_objc_strip_action(ctx):
        return _register_binary_strip_action(
            ctx,
            name,
            binary,
            feature_configuration,
            apple_platform_info,
            extra_link_args,
        )
    else:
        return binary

def _build_feature_configuration(common_variables):
    ctx = common_variables.ctx

    enabled_features = []
    enabled_features.extend(ctx.features)
    enabled_features.extend(common_variables.extra_enabled_features)

    disabled_features = []
    disabled_features.extend(ctx.disabled_features)
    disabled_features.extend(common_variables.extra_disabled_features)
    disabled_features.append("parse_headers")

    enabled_features.append("module_maps")
    enabled_features.append("compile_all_modules")
    enabled_features.append("only_doth_headers_in_module_maps")
    enabled_features.append("exclude_private_headers_in_module_maps")
    enabled_features.append("module_map_without_extern_module")
    disabled_features.append("generate_submodules")

    return cc_common.configure_features(
        ctx = common_variables.ctx,
        cc_toolchain = common_variables.toolchain,
        language = "objc",
        requested_features = enabled_features,
        unsupported_features = disabled_features,
    )

def _register_configuration_specific_link_actions(
        name,
        common_variables,
        cc_linking_context,
        apple_platform_info,
        extra_link_args,
        stamp,
        user_variable_extensions,
        additional_outputs,
        extra_link_inputs,
        attr_linkopts):
    ctx = common_variables.ctx
    feature_configuration = _build_feature_configuration(common_variables)

    if _emit_builtin_objc_strip_action(ctx):
        binary = ctx.actions.declare_shareable_artifact(
            paths.join(ctx.label.package, name + "_unstripped"),
            apple_platform_info.target_build_config.bin_dir,
        )
    else:
        binary = ctx.actions.declare_shareable_artifact(
            paths.join(ctx.label.package, name),
            apple_platform_info.target_build_config.bin_dir,
        )

    if cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "use_cpp_variables_for_objc_executable",
    ):
        return _register_configuration_specific_link_actions_with_cpp_variables(
            name,
            binary,
            common_variables,
            feature_configuration,
            cc_linking_context,
            apple_platform_info,
            extra_link_args,
            stamp,
            user_variable_extensions,
            additional_outputs,
            extra_link_inputs,
            attr_linkopts,
        )
    else:
        return _register_configuration_specific_link_actions_with_objc_variables(
            name,
            binary,
            common_variables,
            feature_configuration,
            cc_linking_context,
            apple_platform_info,
            extra_link_args,
            stamp,
            user_variable_extensions,
            additional_outputs,
            extra_link_inputs,
            attr_linkopts,
        )

def link_multi_arch_binary(*, ctx, cc_toolchains, stamp = -1):
    """Copied from rules_apple.

    Args:
        ctx: rule ctx
        cc_toolchains: split toolchain attr
        stamp: See upstream docs

    Returns:
        struct of linking info
    """

    # TODO: Delete when we drop bazel 7.x
    legacy_linking_function = getattr(apple_common, "link_multi_arch_binary", None)
    if legacy_linking_function:
        return legacy_linking_function(ctx = ctx, stamp = stamp)

    split_deps = ctx.split_attr.deps

    if split_deps and split_deps.keys() != cc_toolchains.keys():
        fail(("Split transition keys are different between 'deps' [%s] and " +
              "'_cc_toolchain_forwarder' [%s]") % (
            split_deps.keys(),
            cc_toolchains.keys(),
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

    for split_transition_key, child_toolchain in cc_toolchains.items():
        cc_toolchain = child_toolchain[CcWrapperInfo].provider
        deps = split_deps.get(split_transition_key, [])
        platform_info = child_toolchain[TestApplePlatformInfo]

        common_variables = compilation_support.build_common_variables(
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
                ctx.bin_dir,
            )
            extensions["dsym_path"] = dsym_binary.path  # dsym symbol file
            additional_outputs.append(dsym_binary)
            legacy_debug_outputs.setdefault(platform_info.target_arch, {})["dsym_binary"] = dsym_binary

        linkmap = None
        if ctx.fragments.cpp.objc_generate_linkmap:
            linkmap = ctx.actions.declare_shareable_artifact(
                ctx.label.package + "/" + ctx.label.name + ".linkmap",
                ctx.bin_dir,
            )
            extensions["linkmap_exec_path"] = linkmap.path  # linkmap file
            additional_outputs.append(linkmap)
            legacy_debug_outputs.setdefault(platform_info.target_arch, {})["linkmap"] = linkmap

        name = ctx.label.name + "_bin"
        executable = _register_configuration_specific_link_actions(
            name = name,
            common_variables = common_variables,
            cc_linking_context = cc_linking_context,
            apple_platform_info = platform_info,
            extra_link_args = [],
            stamp = stamp,
            user_variable_extensions = extensions,
            additional_outputs = additional_outputs,
            extra_link_inputs = [],
            attr_linkopts = attr_linkopts,
        )

        output = {
            "binary": executable,
            "platform": platform_info.target_os,
            "architecture": platform_info.target_arch,
            "environment": platform_info.target_environment,
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

def _build_fully_linked_variable_extensions(*, archive, libs):
    extensions = {}
    extensions["fully_linked_archive_path"] = archive.path
    extensions["objc_library_exec_paths"] = [lib.path for lib in libs]
    extensions["cc_library_exec_paths"] = []
    extensions["imported_library_exec_paths"] = []
    return extensions

def _register_fully_link_action(*, cc_linking_context, common_variables, name):
    ctx = common_variables.ctx
    feature_configuration = _build_feature_configuration(common_variables)

    libraries_to_link = _libraries_from_linking_context(cc_linking_context).to_list()
    libraries = _get_libraries_for_linking(libraries_to_link)

    output_archive = ctx.actions.declare_file(name + ".a")
    extensions = _build_fully_linked_variable_extensions(
        archive = output_archive,
        libs = libraries,
    )

    return cc_common.link(
        actions = ctx.actions,
        additional_inputs = libraries,
        cc_toolchain = common_variables.toolchain,
        feature_configuration = feature_configuration,
        language = "objc",
        name = name,
        output_type = "archive",
        variables_extension = extensions,
    )

def link_multi_arch_static_library(*, ctx, cc_toolchains):
    """Copied from rules_apple.

    Args:
        ctx: rule ctx
        cc_toolchains: split toolchain attr

    Returns:
        struct of linking info
    """

    # TODO: Delete when we drop bazel 7.x
    legacy_linking_function = getattr(apple_common, "link_multi_arch_static_library", None)
    if legacy_linking_function:
        return legacy_linking_function(ctx = ctx)

    split_deps = ctx.split_attr.deps
    split_avoid_deps = ctx.split_attr.avoid_deps

    outputs = []

    for split_transition_key, child_toolchain in cc_toolchains.items():
        cc_toolchain = child_toolchain[CcWrapperInfo].provider
        common_variables = compilation_support.build_common_variables(
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
                if ObjcInfo in dep:
                    avoid_objc_providers.append(dep[ObjcInfo])
                if CcInfo in dep:
                    avoid_cc_providers.append(dep[CcInfo])
                    avoid_cc_linking_contexts.append(dep[CcInfo].linking_context)

        name = ctx.label.name + "-" + cc_toolchain.target_gnu_system_name + "-fl"

        cc_linking_context = _subtract_linking_contexts(
            owner = ctx.label,
            linking_contexts = common_variables.objc_linking_context.cc_linking_contexts,
            avoid_dep_linking_contexts = avoid_cc_linking_contexts,
        )
        linking_outputs = _register_fully_link_action(
            name = name,
            common_variables = common_variables,
            cc_linking_context = cc_linking_context,
        )

        output = {
            "library": linking_outputs.library_to_link.static_library,
        }

        platform_info = child_toolchain[TestApplePlatformInfo]
        output["platform"] = platform_info.target_os
        output["architecture"] = platform_info.target_arch
        output["environment"] = platform_info.target_environment

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
