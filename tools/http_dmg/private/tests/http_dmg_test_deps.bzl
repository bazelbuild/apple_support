"""Bzlmod module extensions that are only used for tests"""

load("//tools/http_dmg:http_dmg.bzl", "http_dmg")

_BUILD_FILE_CONTENT = """\
alias(
    name = "info_plist",
    actual = "{file}",
    visibility = ["//visibility:public"],
)
"""

def http_dmg_test_deps():
    """Download test dependencies for the `http_dmg` repository rule

    Returns:
        the names of instantiated repositories.
    """
    http_dmg(
        name = "http_dmg_test_firefox",
        urls = ["https://ftp.mozilla.org/pub/firefox/releases/141.0.3/mac/en-US/Firefox%20141.0.3.dmg"],
        integrity = "sha256-u5Is2mkFQ73aofvDs8ulCMYHdIMmQ0UrwmZZUzH0LbE=",
        # Explicitly test `build_file`.
        build_file = Label("//tools/http_dmg/private/tests:BUILD.firefox.bazel"),
    )

    http_dmg(
        name = "http_dmg_test_firefox_strip_prefix",
        urls = ["https://ftp.mozilla.org/pub/firefox/releases/141.0.3/mac/en-US/Firefox%20141.0.3.dmg"],
        integrity = "sha256-u5Is2mkFQ73aofvDs8ulCMYHdIMmQ0UrwmZZUzH0LbE=",
        strip_prefix = "Firefox.app",
        build_file_content = _BUILD_FILE_CONTENT.format(
            file = "Contents/Info.plist",
        ),
    )

    http_dmg(
        name = "http_dmg_test_krita",
        urls = ["https://download.kde.org/Attic/krita/5.2.6/krita-5.2.6-release.dmg"],
        integrity = "sha256-DVgCTYuccgEk+1b0d7c5mV/3haqzCVz7IBdYbYQfO/Y=",
        build_file_content = _BUILD_FILE_CONTENT.format(
            file = "krita.app/Contents/Info.plist",
        ),
    )

    http_dmg(
        name = "http_dmg_test_krita_strip_prefix",
        urls = ["https://download.kde.org/Attic/krita/5.2.6/krita-5.2.6-release.dmg"],
        integrity = "sha256-DVgCTYuccgEk+1b0d7c5mV/3haqzCVz7IBdYbYQfO/Y=",
        strip_prefix = "krita.app",
        build_file_content = _BUILD_FILE_CONTENT.format(
            file = "Contents/Info.plist",
        ),
    )

    return [
        "http_dmg_test_firefox",
        "http_dmg_test_firefox_strip_prefix",
        "http_dmg_test_krita",
        "http_dmg_test_krita_strip_prefix",
    ]
