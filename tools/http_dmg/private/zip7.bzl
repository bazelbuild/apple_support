"""Helpers for downloading a hermetic copy of 7-Zip within a repository rule.

7-Zip is the only cross-platform tool that ships prebuilt binaries for Linux,
macOS, and Windows and can read `.dmg` images (UDIF containers wrapping HFS+ or
APFS filesystems, including LZFSE compressed chunks).
"""

load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "get_auth",
)

def _zip7_data(
        *,
        urls,
        integrity,
        bin_path):
    return struct(
        urls = urls,
        integrity = integrity,
        bin_path = bin_path,
    )

# Note: `7zzs` is the statically linked Linux build, `7zz` is dynamically
# linked against glibc. Both ship in the same tarball.
_LINUX_ARM64 = _zip7_data(
    urls = [
        "https://mirror.bazel.build/www.7-zip.org/a/7z2501-linux-arm64.tar.xz",
        "https://github.com/ip7z/7zip/releases/download/25.01/7z2501-linux-arm64.tar.xz",
        "https://www.7-zip.org/a/7z2501-linux-arm64.tar.xz",
    ],
    integrity = "sha256-OcUUDwLORDZZkwPFmhSfZUyxu8R83BBalCEg10euBA0=",
    bin_path = "7zzs",
)

_LINUX_X86_64 = _zip7_data(
    urls = [
        "https://mirror.bazel.build/www.7-zip.org/a/7z2501-linux-x64.tar.xz",
        "https://github.com/ip7z/7zip/releases/download/25.01/7z2501-linux-x64.tar.xz",
        "https://www.7-zip.org/a/7z2501-linux-x64.tar.xz",
    ],
    integrity = "sha256-TKO3xvL2eGa5JiKBi1gjPccDZ74vNrSY6wveqqRLU/Q=",
    bin_path = "7zzs",
)

# The macOS archive contains a universal binary.
_MACOS = _zip7_data(
    urls = [
        "https://mirror.bazel.build/www.7-zip.org/a/7z2501-mac.tar.xz",
        "https://github.com/ip7z/7zip/releases/download/25.01/7z2501-mac.tar.xz",
        "https://www.7-zip.org/a/7z2501-mac.tar.xz",
    ],
    integrity = "sha256-Jqp1vCYrsQvwgFYXuVVpwwNcLFkKmffbVcfpYHsmheA=",
    bin_path = "7zz",
)

# `7zr.exe` is a reduced 32-bit console build that only understands `.7z`
# archives (and 7-Zip's own SFX installers). It is used purely to bootstrap the
# full `7z.exe` + `7z.dll` from the installer below. 7-zip.org serves it
# unversioned and has already replaced it since this pin was taken, so only
# versioned URLs are listed here.
_WINDOWS_BOOTSTRAP = _zip7_data(
    urls = [
        "https://mirror.bazel.build/www.7-zip.org/a/7zr.exe",
        "https://github.com/ip7z/7zip/releases/download/25.01/7zr.exe",
    ],
    integrity = "sha256-J8vj1YBK0J6Qu8qpFtoNXDsL6UYtDg+2y1S+XtkDCHU=",
    bin_path = "7zr.exe",
)

ZIP7_SOURCES = {
    "linux_arm64": _LINUX_ARM64,
    "linux_x86_64": _LINUX_X86_64,
    "macos_arm64": _MACOS,
    "macos_x86_64": _MACOS,
    "windows_arm64": _WINDOWS_BOOTSTRAP,
    "windows_i686": _WINDOWS_BOOTSTRAP,
    "windows_x86_64": _WINDOWS_BOOTSTRAP,
}

# Secondary archives which are extracted using the binary from `ZIP7_SOURCES`.
# On Windows these are the official installers, which are 7-Zip SFX archives
# containing the full `7z.exe` and `7z.dll` for the host architecture.
ZIP7_EXTRAS = {
    "windows_arm64": _zip7_data(
        urls = [
            "https://mirror.bazel.build/www.7-zip.org/a/7z2501-arm64.exe",
            "https://github.com/ip7z/7zip/releases/download/25.01/7z2501-arm64.exe",
            "https://www.7-zip.org/a/7z2501-arm64.exe",
        ],
        integrity = "sha256-Y2XHxE4he5wQCeBl2vn5qjdFTmQxW0qqJj9/jwYHVdw=",
        bin_path = "7z.exe",
    ),
    "windows_i686": _zip7_data(
        urls = [
            "https://mirror.bazel.build/7-zip.org/a/7z2501.exe",
            "https://github.com/ip7z/7zip/releases/download/25.01/7z2501.exe",
            "https://www.7-zip.org/a/7z2501.exe",
        ],
        integrity = "sha256-uWgx7sWSg4TwVD1rV8H4ApUqDyZo5mKILAp4WitS+zs=",
        bin_path = "7z.exe",
    ),
    "windows_x86_64": _zip7_data(
        urls = [
            "https://mirror.bazel.build/7-zip.org/a/7z2501-x64.exe",
            "https://github.com/ip7z/7zip/releases/download/25.01/7z2501-x64.exe",
            "https://www.7-zip.org/a/7z2501-x64.exe",
        ],
        integrity = "sha256-eK+iocdzyvPPft9i+FfSqKXaVfsP/12kFgdMDSiytV8=",
        bin_path = "7z.exe",
    ),
}

def zip7_host_arch(ctx):
    """Identify the host platform.

    Args:
        ctx (repository_ctx): The rule's repository context.

    Returns:
        str: A key of `ZIP7_SOURCES`.
    """
    arch = ctx.os.arch
    if arch == "amd64":
        arch = "x86_64"
    elif arch == "aarch64":
        arch = "arm64"
    elif arch == "x86":
        arch = "i686"

    if "linux" in ctx.os.name:
        host = "linux_{}".format(arch)
    elif "mac" in ctx.os.name:
        host = "macos_{}".format(arch)
    elif "win" in ctx.os.name:
        host = "windows_{}".format(arch)
    else:
        fail("Unknown host OS: {}".format(ctx.os.name))

    if host not in ZIP7_SOURCES:
        fail("7-Zip is not available for host `{}`. Supported hosts: {}".format(
            host,
            sorted(ZIP7_SOURCES.keys()),
        ))

    return host

def zip7_extract(
        *,
        repository_ctx,
        zip7_bin,
        archive,
        output,
        extra_args = []):
    """Extract an archive using 7-Zip.

    Args:
        repository_ctx (repository_ctx): The rule's repository context.
        zip7_bin (path): The path to a 7-Zip binary.
        archive (path): The archive to extract.
        output (path): The directory to extract into.
        extra_args (list): Additional arguments to pass to 7-Zip.
    """
    command = [zip7_bin, "x", archive, "-o{}".format(output), "-y"] + extra_args
    result = repository_ctx.execute(command)
    if result.return_code != 0:
        fail("7z command failed with exit code {}\n{}\n\nstdout:\n{}\nstderr:\n{}".format(
            result.return_code,
            " ".join([str(a) for a in command]),
            result.stdout,
            result.stderr,
        ))

_BAZEL_ARCHIVE_SUFFIXES = (
    ".tar.bz2",
    ".tar.gz",
    ".tar.xz",
    ".tar.zst",
    ".tar",
    ".tbz",
    ".tgz",
    ".txz",
    ".tzst",
    ".zip",
)

def zip7_download(repository_ctx, output):
    """Download a pinned 7-Zip binary for the host platform.

    Args:
        repository_ctx (repository_ctx): The rule's repository context.
        output (str): The directory, relative to the repository, to download into.

    Returns:
        path: The path to the 7-Zip binary.
    """
    host = zip7_host_arch(repository_ctx)
    source = ZIP7_SOURCES[host]
    extras = ZIP7_EXTRAS.get(host)

    repository_ctx.report_progress("Downloading 7-Zip.")
    output_dir = repository_ctx.path(output)
    bin_path = output_dir.get_child(source.bin_path)
    if source.urls[0].endswith(_BAZEL_ARCHIVE_SUFFIXES):
        repository_ctx.download_and_extract(
            url = source.urls,
            output = output_dir,
            integrity = source.integrity,
            auth = get_auth(repository_ctx, source.urls),
        )
    else:
        repository_ctx.download(
            url = source.urls,
            output = bin_path,
            integrity = source.integrity,
            executable = True,
            auth = get_auth(repository_ctx, source.urls),
        )

    if not bin_path.exists:
        fail("Failed to locate the 7-Zip binary `{}` from: {}".format(source.bin_path, source.urls))

    if not extras:
        return bin_path

    repository_ctx.report_progress("Downloading 7-Zip extras.")
    extras_archive = output_dir.get_child("extras_archive")
    extras_dir = output_dir.get_child("extras")
    repository_ctx.download(
        url = extras.urls,
        output = extras_archive,
        integrity = extras.integrity,
        auth = get_auth(repository_ctx, extras.urls),
    )
    zip7_extract(
        repository_ctx = repository_ctx,
        zip7_bin = bin_path,
        archive = extras_archive,
        output = extras_dir,
    )
    repository_ctx.delete(extras_archive)

    extras_bin_path = extras_dir.get_child(extras.bin_path)
    if not extras_bin_path.exists:
        fail("Failed to locate the 7-Zip binary `{}` from: {}".format(extras.bin_path, extras.urls))

    return extras_bin_path
