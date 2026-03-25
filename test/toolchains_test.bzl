"""Test framework for diffing cc_toolchain config against checked-in golden files."""

load("@bazel_features//private:util.bzl", bazel_version_ge = "ge")
load(
    "@rules_cc//cc/toolchains:cc_toolchain_config_info.bzl",
    "CcToolchainConfigInfo",
)
load("//configs:platforms.bzl", "APPLE_PLATFORMS_CONSTRAINTS")

def _platform_transition_impl(_settings, attr):
    return {"//command_line_option:platforms": [attr.platform]}

_platform_transition = transition(
    implementation = _platform_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:platforms"],
)

def _sanitize_path(path):
    if not path:
        return path

    # /Users/<username>/foo -> /USER_HOME/foo
    parts = path.split("/")
    if len(parts) >= 3 and parts[0] == "" and parts[1] == "Users":
        return "/USER_HOME/" + "/".join(parts[3:])
    return path

_SANITIZED_ENV_KEYS = ["APPLE_SDK_VERSION_OVERRIDE", "APPLE_SUPPORT_MODULEMAP", "XCODE_VERSION_OVERRIDE"]

def _strip_triple_version(triple):
    """Replace OS version in a target triple with VERSION.

    Split on '-', strip digits and dots from the 3rd component, rejoin.
    e.g. arm64-apple-macosx26.2 -> arm64-apple-macosxVERSION
         arm64-apple-ios26.2-simulator -> arm64-apple-iosVERSION-simulator
    """
    parts = triple.split("-")
    os_part = parts[2]
    stripped = ""
    for c in os_part.elems():
        if c.isdigit() or c == ".":
            break
        stripped += c
    parts[2] = stripped + "VERSION"
    return "-".join(parts)

def _sanitize_env_entries(features):
    """Replace machine-specific env values with placeholders."""
    replacements = {}
    for feat in features:
        for es in feat.env_sets:
            for entry in es.env_entries:
                if entry.key in _SANITIZED_ENV_KEYS:
                    replacements[entry.value] = entry.key + "_PLACEHOLDER"
    return replacements

def _config_to_json(config_info):
    # convert struct to dict
    output = json.decode(json.encode(config_info))
    output["cxx_builtin_include_directories"] = [
        _sanitize_path(x)
        for x in config_info.cxx_builtin_include_directories
    ]
    result = json.encode_indent(output, indent = "  ")

    for old, new in _sanitize_env_entries(config_info._features_DO_NOT_USE).items():
        result = result.replace(json.encode(old), json.encode(new))

    # Replace the versioned triple with a VERSION placeholder
    triple = config_info.target_system_name
    sanitized_triple = _strip_triple_version(triple)
    result = result.replace(triple, sanitized_triple)

    return result

def _toolchain_config_test_impl(ctx):
    config_info = ctx.attr.toolchain_config[0][CcToolchainConfigInfo]
    actual_json = _config_to_json(config_info)

    golden = ctx.file.golden
    test_script = ctx.actions.declare_file(ctx.label.name + ".sh")
    actual_file = ctx.actions.declare_file(ctx.label.name + ".actual.json")

    ctx.actions.write(
        output = actual_file,
        content = actual_json,
    )

    ctx.actions.write(
        output = test_script,
        content = """\
#!/usr/bin/env bash

set -euo pipefail

if ! diff -u "$GOLDEN" "$ACTUAL"; then
  echo ""
  echo "ERROR: Toolchain config does not match golden file."
  echo "To update, run: bazel run {update_target}"
  exit 1
fi
""".format(update_target = str(ctx.label).rsplit("_test", 1)[0] + "_update"),
        is_executable = True,
    )

    return [DefaultInfo(
        executable = test_script,
        runfiles = ctx.runfiles(files = [actual_file, golden]),
    ), RunEnvironmentInfo(environment = {
        "ACTUAL": actual_file.short_path,
        "GOLDEN": golden.short_path,
    })]

_toolchain_config_test = rule(
    implementation = _toolchain_config_test_impl,
    test = True,
    attrs = {
        "toolchain_config": attr.label(
            mandatory = True,
            providers = [CcToolchainConfigInfo],
            cfg = _platform_transition,
        ),
        "golden": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "platform": attr.string(mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def _toolchain_config_update_impl(ctx):
    config_info = ctx.attr.toolchain_config[0][CcToolchainConfigInfo]
    actual_json = _config_to_json(config_info)

    actual_file = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.write(
        output = actual_file,
        content = actual_json,
    )

    update_script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = update_script,
        content = """\
#!/usr/bin/env bash

set -euo pipefail

actual="${{RUNFILES_DIR:-$0.runfiles}}/{workspace}/{actual}"
golden="{golden_path}"
cp "$actual" "${{BUILD_WORKSPACE_DIRECTORY}}/${{golden}}"
echo "Updated $golden"
""".format(
            workspace = ctx.workspace_name,
            actual = actual_file.short_path,
            golden_path = ctx.file.golden.short_path,
        ),
        is_executable = True,
    )

    return [DefaultInfo(
        executable = update_script,
        runfiles = ctx.runfiles(files = [actual_file]),
    ), _UpdateInfo(
        actual = actual_file,
        golden_path = ctx.file.golden.short_path,
    )]

_UpdateInfo = provider(
    fields = ["actual", "golden_path"],
    doc = "",
)

_toolchain_config_update = rule(
    implementation = _toolchain_config_update_impl,
    executable = True,
    attrs = {
        "toolchain_config": attr.label(
            mandatory = True,
            providers = [CcToolchainConfigInfo],
            cfg = _platform_transition,
        ),
        "golden": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "platform": attr.string(mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

_is_bazel_9_or_later = bazel_version_ge("9.0.0")

def toolchain_config_test_suite(name):
    """Create toolchain config tests for all platforms.

    Args:
        name: Name for the test suite.
    """
    if not _is_bazel_9_or_later:
        # Bazel 7.x/8.x use proto encoding for CcToolchainConfigInfo
        # instead of JSON, so these tests don't work there.
        native.test_suite(name = name, tests = [])
        return

    platforms = APPLE_PLATFORMS_CONSTRAINTS.keys()
    toolchain_config = "//toolchain:toolchain_config"
    tests = []
    updates = []
    for platform in platforms:
        golden = "//test/test_data/toolchain_configs:" + platform + ".json"
        platform_label = "//platforms:" + platform

        test_name = name + "_" + platform + "_test"
        _toolchain_config_test(
            name = test_name,
            toolchain_config = toolchain_config,
            golden = golden,
            platform = platform_label,
        )
        tests.append(test_name)

        update_name = name + "_" + platform + "_update"
        _toolchain_config_update(
            name = update_name,
            toolchain_config = toolchain_config,
            golden = golden,
            platform = platform_label,
        )
        updates.append(update_name)

    native.test_suite(
        name = name,
        tests = tests,
    )

    _update_all(
        name = name + "_update_all",
        updates = updates,
    )

def _update_all_impl(ctx):
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    lines = ["#!/usr/bin/env bash", "set -euo pipefail"]
    all_files = []
    for update in ctx.attr.updates:
        info = update[_UpdateInfo]
        all_files.append(info.actual)
        lines.append('cp "${{RUNFILES_DIR:-$0.runfiles}}/{workspace}/{actual}" "${{BUILD_WORKSPACE_DIRECTORY}}/{golden}"'.format(
            workspace = ctx.workspace_name,
            actual = info.actual.short_path,
            golden = info.golden_path,
        ))
        lines.append('echo "Updated {golden}"'.format(golden = info.golden_path))
    ctx.actions.write(
        output = script,
        content = "\n".join(lines) + "\n",
        is_executable = True,
    )
    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = all_files),
    )]

_update_all = rule(
    implementation = _update_all_impl,
    executable = True,
    attrs = {
        "updates": attr.label_list(providers = [_UpdateInfo]),
    },
)
