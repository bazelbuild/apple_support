"""http_dmg"""

load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "get_auth",
)

def _zip7_data(
        *,
        url,
        integrity,
        bin_path = None):
    return struct(
        url = url,
        integrity = integrity,
        bin_path = bin_path,
    )

_7ZIP_SOURCES = {
    "linux_arm64": _zip7_data(
        url = "https://www.7-zip.org/a/7z2501-linux-arm64.tar.xz",
        integrity = "sha256-OcUUDwLORDZZkwPFmhSfZUyxu8R83BBalCEg10euBA0=",
        bin_path = "7zz",
    ),
    "linux_x86_64": _zip7_data(
        url = "https://www.7-zip.org/a/7z2501-linux-x64.tar.xz",
        integrity = "sha256-TKO3xvL2eGa5JiKBi1gjPccDZ74vNrSY6wveqqRLU/Q=",
        bin_path = "7zz",
    ),
    "macos_arm64": _zip7_data(
        url = "https://www.7-zip.org/a/7z2501-mac.tar.xz",
        integrity = "sha256-Jqp1vCYrsQvwgFYXuVVpwwNcLFkKmffbVcfpYHsmheA=",
        bin_path = "7zz",
    ),
    "macos_x86_64": _zip7_data(
        url = "https://www.7-zip.org/a/7z2501-mac.tar.xz",
        integrity = "sha256-Jqp1vCYrsQvwgFYXuVVpwwNcLFkKmffbVcfpYHsmheA=",
        bin_path = "7zz",
    ),
    "windows_i686": _zip7_data(
        url = "https://www.7-zip.org/a/7zr.exe",
        integrity = "sha256-J8vj1YBK0J6Qu8qpFtoNXDsL6UYtDg+2y1S+XtkDCHU=",
        bin_path = "7zr.exe",
    ),
    "windows_x86_64": _zip7_data(
        url = "https://www.7-zip.org/a/7zr.exe",
        integrity = "sha256-J8vj1YBK0J6Qu8qpFtoNXDsL6UYtDg+2y1S+XtkDCHU=",
        bin_path = "7zr.exe",
    ),
}

_7ZIP_EXTRAS = {
    "windows_i686": _zip7_data(
        url = "https://7-zip.org/a/7z2501-x64.exe",
        integrity = "sha256-eK+iocdzyvPPft9i+FfSqKXaVfsP/12kFgdMDSiytV8=",
        bin_path = "7z.exe",
    ),
    "windows_x86_64": _zip7_data(
        url = "https://7-zip.org/a/7z2501.exe",
        integrity = "sha256-uWgx7sWSg4TwVD1rV8H4ApUqDyZo5mKILAp4WitS+zs=",
        bin_path = "7z.exe",
    ),
}

def _host_arch(repository_ctx):
    arch = repository_ctx.os.arch
    if arch == "amd64":
        arch = "x86_64"
    elif arch == "aarch64":
        arch = "arm64"

    if "linux" in repository_ctx.os.name:
        return "linux_{}".format(arch)

    if "mac" in repository_ctx.os.name:
        return "macos_{}".format(arch)

    if "win" in repository_ctx.os.name:
        return "windows_{}".format(arch)

    fail("Unknown host OS: {}".format(repository_ctx.os.name))

_DMG_IGNORES_PATTERNS = {
    "name": (
        "Applications",
    ),
    "prefix": (
        ".DS_Store",
        ".background",
        ".VolumeIcon",
    ),
    "suffix": (
        "[]",
        "[HFS+ Private Data]",
        ".fseventsd",
    ),
}

def _7z_readdir(path, is_dmg):
    """Read the contents of a directory, ignoring certain patterns for dmg archives.

    Args:
        path (Path): The directory Path object
        is_dmg (bool): Whether or not the directory is from a `.dmg` archive.

    Returns:
        list: A list of Path.
    """
    if not is_dmg:
        return path.readdir()

    entries = []

    for item in path.readdir():
        if item.basename.endswith(_DMG_IGNORES_PATTERNS["suffix"]):
            continue
        if item.basename.startswith(_DMG_IGNORES_PATTERNS["prefix"]):
            continue
        if item.basename in _DMG_IGNORES_PATTERNS["name"]:
            continue

        # 7zip will write attributes using `:` delimiters.
        if ":" in item.basename:
            continue

        entries.append(item)

    return entries

def _move(repository_ctx, src, dst):
    if not hasattr(repository_ctx, "rename"):
        program = "mv"
        if "win" in repository_ctx.os.name:
            program = "move"
        result = repository_ctx.execute([program, src, dst])
        if result.return_code:
            fail("mv failed with {}\nstdout:\n{}\nstderr:\n{}".format(
                result.return_code,
                result.stdout,
                result.stderr,
            ))
        return

    repository_ctx.rename(src, dst)

def _extract_7z(
        *,
        repository_ctx,
        z7_bin,
        archive,
        output = None,
        strip_prefix = None):
    """Extract a 7zip archive to the repository directory.

    Args:
        repository_ctx (repository_ctx): The rule's repository context.
        z7_bin (path): The path to a 7zip binary.
        archive (path): path to the archive that will be unpacked, relative to the repository directory.
        output (str, optional): path to the directory where the archive will be unpacked, relative to the repository directory.
        strip_prefix (str, optional): a directory prefix to strip from the extracted files.
    """
    if not output:
        output = "."

    out_dir = repository_ctx.path(output)
    temp_out_dir = repository_ctx.path("{}/_7z_out".format(out_dir))

    command = [z7_bin, "x", archive, "-snld", "-o{}".format(temp_out_dir), "-y"]
    result = repository_ctx.execute(command)
    if result.return_code != 0:
        fail("7z command failed with exit code {}\n{}\n\nstdout:\n{}\nstderr:\n{}".format(
            result.return_code,
            " ".join([str(a) for a in command]),
            result.stdout,
            result.stderr,
        ))

    is_dmg = str(archive).endswith((".dmg", ".DMG"))

    target_dir = temp_out_dir
    if is_dmg:
        entries = temp_out_dir.readdir()
        if len(entries) == 1 and entries[0].is_dir:
            target_dir = entries[0]

    # Check to see if any prefixes can be stripped
    if strip_prefix:
        stripped_dir = target_dir.get_child(strip_prefix)
        if not stripped_dir.exists:
            fail("Prefix \"{}\" was given, but not found in the archive. Here are possible prefixes for this archive: {}".format(
                strip_prefix,
                [p.basename for p in _7z_readdir(target_dir, is_dmg)],
            ))
        target_dir = stripped_dir

    # Move the extracted contents to the root of the directory, leaving known bad files.
    for item in _7z_readdir(target_dir, is_dmg):
        _move(repository_ctx, item, repository_ctx.path("{}/{}".format(output, item.basename)))

    repository_ctx.delete(temp_out_dir)

def _download_and_extract_7zip_binary(repository_ctx, host_arch):
    """Fetch and extract a 7zip archive

    7z is a cross platform way to extract dmg file.

    Args:
        repository_ctx (repository_ctx): The rule's context object.
        host_arch (str): An identifier for the host os and architecture.

    Returns:
        tuple:
            - path: The directory in which 7zip was downloaded to.
            - path: The path to the 7zip binary.
    """
    zip_data = _7ZIP_SOURCES[host_arch]

    auth = get_auth(repository_ctx, [zip_data.url])

    zip_dir = repository_ctx.path("7z")
    zip_exe = repository_ctx.path("{}/{}".format(zip_dir, zip_data.bin_path))

    if zip_data.url.endswith(".exe"):
        repository_ctx.download(
            url = zip_data.url,
            output = zip_exe,
            integrity = zip_data.integrity,
            executable = True,
            auth = auth,
        )
    else:
        repository_ctx.download_and_extract(
            url = zip_data.url,
            integrity = zip_data.integrity,
            output = zip_dir,
            auth = auth,
        )

    extras = _7ZIP_EXTRAS.get(host_arch)
    if extras:
        extras_output = repository_ctx.path("{}/{}".format(
            zip_dir,
            "extras",
        ))
        _, _, url_suffix = extras.url.rpartition(".")
        if url_suffix in ("7z", "msi", "exe"):
            extras_archive = repository_ctx.path("{}/{}".format(
                zip_dir,
                "extras.{}".format(url_suffix),
            ))
            repository_ctx.download(
                url = extras.url,
                output = extras_archive,
                integrity = extras.integrity,
                auth = auth,
            )
            _extract_7z(
                repository_ctx = repository_ctx,
                z7_bin = zip_exe,
                archive = extras_archive,
                output = extras_output,
            )
        else:
            repository_ctx.download_and_extract(
                url = extras.url,
                integrity = extras.integrity,
                output = extras_output,
                auth = auth,
            )

        # Allow extras to update the binary to use.
        if extras.bin_path:
            zip_exe = repository_ctx.path("{}/{}".format(extras_output, extras.bin_path))

    if not zip_exe.exists:
        fail("Failed to locate 7z binary from: {}".format(zip_data.url))

    return zip_dir, zip_exe

def _http_dmg_impl(repository_ctx):
    if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
        fail("Only one of build_file and build_file_content can be provided.")

    repository_ctx.report_progress("Downloading 7z.")
    host_arch = _host_arch(repository_ctx)
    z7_dir, z7_bin = _download_and_extract_7zip_binary(repository_ctx, host_arch)
    dmg = repository_ctx.path("dmg.dmg")

    repository_ctx.report_progress("Downloading dmg.")
    download_results = repository_ctx.download(
        url = repository_ctx.attr.urls,
        output = dmg,
        integrity = repository_ctx.attr.integrity,
        sha256 = repository_ctx.attr.sha256,
        auth = get_auth(repository_ctx, repository_ctx.attr.urls),
    )

    repository_ctx.report_progress("Extracting dmg.")
    _extract_7z(
        repository_ctx = repository_ctx,
        z7_bin = z7_bin,
        archive = dmg,
        strip_prefix = repository_ctx.attr.strip_prefix,
    )

    build_file_content = repository_ctx.attr.build_file_content
    if repository_ctx.attr.build_file:
        repository_ctx.read(repository_ctx.path(repository_ctx.attr.build_file))
    repository_ctx.file("BUILD.bazel", content = build_file_content)
    repository_ctx.file("WORKSPACE.bazel", content = """workspace(name = "{}")""".format(repository_ctx.name))

    # Delete dmg remnants
    repository_ctx.delete(dmg)
    repository_ctx.delete(z7_dir)

    # Return reproducibility attributes
    repro_attrs = {
        k: getattr(repository_ctx.attr, k)
        for k in _ATTRS.keys()
    }

    repro_attrs["name"] = repository_ctx.attr.name

    if not repository_ctx.attr.sha256:
        repro_attrs["integrity"] = download_results.integrity

    return repro_attrs

_ATTRS = {
    "auth_patterns": attr.string_dict(
        doc = """An optional dict mapping host names to custom authorization patterns.

If a URL's host name is present in this dict the value will be used as a pattern when
generating the authorization header for the http request. This enables the use of custom
authorization schemes used in a lot of common cloud storage providers.

The pattern currently supports 2 tokens: <code>&lt;login&gt;</code> and
<code>&lt;password&gt;</code>, which are replaced with their equivalent value
in the netrc file for the same host name. After formatting, the result is set
as the value for the <code>Authorization</code> field of the HTTP request.

Example attribute and netrc for a http download to an oauth2 enabled API using a bearer token:

<pre>
auth_patterns = {
    "storage.cloudprovider.com": "Bearer &lt;password&gt;"
}
</pre>

netrc:

<pre>
machine storage.cloudprovider.com
        password RANDOM-TOKEN
</pre>

The final HTTP request would have the following header:

<pre>
Authorization: Bearer RANDOM-TOKEN
</pre>
""",
    ),
    "build_file": attr.label(
        allow_single_file = True,
        doc =
            "The file to use as the BUILD file for this repository." +
            "This attribute is an absolute label (use '@//' for the main " +
            "repo). The file does not need to be named BUILD, but can " +
            "be (something like BUILD.new-repo-name may work well for " +
            "distinguishing it from the repository's actual BUILD files. " +
            "Either build_file or build_file_content can be specified, but " +
            "not both.",
    ),
    "build_file_content": attr.string(
        doc =
            "The content for the BUILD file for this repository. " +
            "Either build_file or build_file_content can be specified, but " +
            "not both.",
    ),
    "integrity": attr.string(
        doc = """Expected checksum in Subresource Integrity format of the file downloaded.

This must match the checksum of the file downloaded. _It is a security risk
to omit the checksum as remote files can change._ At best omitting this
field will make your build non-hermetic. It is optional to make development
easier but either this attribute or `sha256` should be set before shipping.""",
    ),
    "netrc": attr.string(
        doc = "Location of the .netrc file to use for authentication",
    ),
    "sha256": attr.string(
        doc = """The expected SHA-256 of the file downloaded.

This must match the SHA-256 of the file downloaded. _It is a security risk
to omit the SHA-256 as remote files can change._ At best omitting this
field will make your build non-hermetic. It is optional to make development
easier but either this attribute or `integrity` should be set before shipping.""",
    ),
    "strip_prefix": attr.string(
        doc = """A directory prefix to strip from the extracted files.

Many archives contain a top-level directory that contains all of the useful
files in archive. Instead of needing to specify this prefix over and over
in the `build_file`, this field can be used to strip it from all of the
extracted files.

For example, suppose you are using `foo-lib-latest.zip`, which contains the
directory `foo-lib-1.2.3/` under which there is a `WORKSPACE` file and are
`src/`, `lib/`, and `test/` directories that contain the actual code you
wish to build. Specify `strip_prefix = "foo-lib-1.2.3"` to use the
`foo-lib-1.2.3` directory as your top-level directory.

Note that if there are files outside of this directory, they will be
discarded and inaccessible (e.g., a top-level license file). This includes
files/directories that start with the prefix but are not in the directory
(e.g., `foo-lib-1.2.3.release-notes`). If the specified prefix does not
match a directory in the archive, Bazel will return an error.""",
    ),
    "urls": attr.string_list(
        doc = """A list of URLs to a file that will be made available to Bazel.

Each entry must be a file, http or https URL. Redirections are followed.
Authentication is not supported.

URLs are tried in order until one succeeds, so you should list local mirrors first.
If all downloads fail, the rule will fail.""",
        mandatory = True,
    ),
}

http_dmg = repository_rule(
    doc = """\
Download and extract a [`.dmg`](https://en.wikipedia.org/wiki/Apple_Disk_Image) file and extract it's
contents for use as a Bazel repository.
""",
    implementation = _http_dmg_impl,
    attrs = _ATTRS,
)
