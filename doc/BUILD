load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@stardoc//stardoc:stardoc.bzl", "stardoc")

_DOC_SRCS = {
    "rules": (
        "//rules:rules.doc.bzl",
        [
            "apple_genrule",
            "toolchain_substitution",
            "universal_binary",
        ],
    ),
    "apple_support": (
        "//lib:apple_support.bzl",
        [
            "apple_support.action_required_attrs",
            "apple_support.path_placeholders.platform_frameworks",
            "apple_support.path_placeholders.sdkroot",
            "apple_support.path_placeholders.xcode",
            "apple_support.platform_constraint_attrs",
            "apple_support.run",
            "apple_support.run_shell",
            "apple_support.target_arch_from_rule_ctx",
            "apple_support.target_environment_from_rule_ctx",
            "apple_support.target_os_from_rule_ctx",
            "apple_support.xcode_path_resolve_level",
        ],
    ),
    "xcode_support": (
        "//lib:xcode_support.bzl",
        [
            "xcode_support.get_current_sdk",
            "xcode_support.get_current_xcode",
            "xcode_support.is_xcode_at_least_version",
        ],
    ),
}

[
    write_file(
        name = file + "_header",
        out = file + "_header.vm",
        content = [
            "<!-- Generated with Stardoc, Do Not Edit! -->",
            "",
            "${moduleDocstring}",
            "On this page:",
            "",
        ] + ["  * [{0}](#{0})".format(r) for r in _DOC_SRCS[file][1]] + [
            "",
        ],
    )
    for file in _DOC_SRCS.keys()
]

[
    stardoc(
        name = file + "_doc",
        out = file + ".md_pre",
        header_template = file + "_header.vm",
        input = doc_file,
        symbol_names = symbols,
        tags = ["no-sandbox"],  # https://github.com/bazelbuild/stardoc/issues/112
        deps = [
            "//rules",
            "//xcode:providers",
        ],
    )
    for [
        file,
        (doc_file, symbols),
    ] in _DOC_SRCS.items()
]

[
    genrule(
        name = "fix_stardoc_" + file,
        srcs = [file + ".md_pre"],
        outs = [file + ".md_"],
        cmd = "sed '/rules.doc.bzl/,+1d' $(SRCS) > $(OUTS)",
    )
    for file in _DOC_SRCS.keys()
]

[
    diff_test(
        name = "test_" + file,
        failure_message = "\nPlease update the docs by running\n    bazel run //doc:update",
        file1 = file + ".md_",
        file2 = file + ".md",
    )
    for file in _DOC_SRCS.keys()
]

write_file(
    name = "gen_update",
    out = "update.sh",
    content = [
        "#!/usr/bin/env bash",
        "cd $BUILD_WORKSPACE_DIRECTORY",
    ] + [
        "cp -fv bazel-bin/doc/{0}.md_ doc/{0}.md".format(
            file,
        )
        for file in _DOC_SRCS.keys()
    ],
)

sh_binary(
    name = "update",
    srcs = ["update.sh"],
    data = [file + ".md_" for file in _DOC_SRCS.keys()],
)
