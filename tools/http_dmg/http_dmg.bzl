"""http_dmg"""

load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "get_auth",
    "patch",
    "update_attrs",
)
load(
    "//tools/http_dmg/private:zip7.bzl",
    "zip7_download",
    "zip7_extract",
)

# Entries which are artifacts of the disk image rather than its payload. Each
# entry is excluded both at the root of the image and directly within the
# volume directory 7-Zip creates for the image.
_DMG_IGNORED_ENTRIES = [
    # Finder metadata.
    ".DS_Store",
    ".background",
    ".VolumeIcon*",
    ".fseventsd",
    ".Trashes",
    # The conventional `Applications -> /Applications` drag target. 7-Zip
    # names symlinks with an empty name `[]`.
    "Applications",
    "[]",
    # HFS+ bookkeeping.
    "[HFS+ Private Data]",
]

def _dmg_7z_args():
    # type: () -> list[str]
    """Arguments passed to 7-Zip when extracting a `.dmg` archive.

    Returns:
        list: A list of strings.
    """
    args = [
        # Do not extract HFS+ extended attributes, which 7-Zip would otherwise
        # write as `<file>:<attribute>` files beside each file.
        "-sns-",
        # Extract all symbolic links, including links to links and links which
        # point outside of the extraction directory. These are common in `.dmg`
        # files (e.g. `Applications -> /Applications`). The archive is
        # checksum pinned so this is safe for the archives a user opts into.
        "-snld20",
    ]

    # 7-Zip wildcards do not match across `/`, so `*/<name>` only matches an
    # entry directly within the volume directory.
    for entry in _DMG_IGNORED_ENTRIES:
        args.append("-x!{}".format(entry))
        args.append("-x!*/{}".format(entry))

    return args

# TODO(https://github.com/bazelbuild/bazel/issues/32020): use a source annotation once Bazel exposes these context and metadata types.
def _move(repository_ctx, src, dst):
    # type: (repository_ctx, path, path) -> None
    # TODO: Delete the fallback once Bazel 7.x is no longer supported.
    # `repository_ctx.rename` was added in Bazel 8.0.
    if hasattr(repository_ctx, "rename"):
        repository_ctx.rename(src, dst)
        return

    # Unlike `rename`, `mv`/`move` do not create parent directories. Writing
    # and deleting a placeholder file creates them without any host tools.
    parent = dst.dirname
    if not parent.exists:
        placeholder = parent.get_child(".http_dmg_mkdir")
        repository_ctx.file(placeholder, content = "", executable = False)
        repository_ctx.delete(placeholder)

    if "win" in repository_ctx.os.name:
        # `move` is a `cmd.exe` builtin rather than an executable.
        command = ["cmd", "/c", "move", src, dst]
    else:
        command = ["mv", src, dst]

    result = repository_ctx.execute(command)
    if result.return_code:
        fail("{} failed with {}\nstdout:\n{}\nstderr:\n{}".format(
            " ".join([str(a) for a in command]),
            result.return_code,
            result.stdout,
            result.stderr,
        ))

def _extract_dmg(
        *,
        repository_ctx,
        zip7_bin,
        archive,
        strip_prefix = None,
        add_prefix = None):
    # type: (repository_ctx, path, path, str | None, str | None) -> None
    """Extract a `.dmg` archive into the repository directory.

    Args:
        repository_ctx (repository_ctx): The rule's repository context.
        zip7_bin (path): The path to a 7-Zip binary.
        archive (path): The `.dmg` archive to extract.
        strip_prefix (str, optional): a directory prefix to strip from the extracted files.
        add_prefix (str, optional): a directory, relative to the repository, to extract into.
    """
    temp_out_dir = repository_ctx.path("_7z_out")

    zip7_extract(
        repository_ctx = repository_ctx,
        zip7_bin = zip7_bin,
        archive = archive,
        output = temp_out_dir,
        extra_args = _dmg_7z_args(),
    )

    # 7-Zip places the contents of the image within a directory named after
    # the volume. Treat that directory as the root of the archive.
    target_dir = temp_out_dir
    entries = temp_out_dir.readdir()
    if len(entries) == 1 and entries[0].is_dir:
        target_dir = entries[0]

    if strip_prefix:
        stripped_dir = target_dir.get_child(strip_prefix)
        if not stripped_dir.exists:
            fail("Prefix \"{}\" was given, but not found in the archive. Here are possible prefixes for this archive: {}".format(
                strip_prefix,
                [p.basename for p in target_dir.readdir()],
            ))
        target_dir = stripped_dir

    dest_dir = repository_ctx.path(add_prefix or ".")
    for item in target_dir.readdir():
        _move(repository_ctx, item, dest_dir.get_child(item.basename))

    repository_ctx.delete(temp_out_dir)

def _http_dmg_impl(repository_ctx):
    # type: (...) -> dict[str, object] | repo_metadata
    if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
        fail("Only one of build_file and build_file_content can be provided.")

    source_urls = _get_source_urls(repository_ctx.attr.url, repository_ctx.attr.urls)

    zip7_dir = "7z"
    zip7_bin = zip7_download(repository_ctx, zip7_dir)
    dmg = repository_ctx.path("dmg.dmg")

    repository_ctx.report_progress("Downloading dmg.")
    download_results = repository_ctx.download(
        url = source_urls,
        output = dmg,
        integrity = repository_ctx.attr.integrity,
        sha256 = repository_ctx.attr.sha256,
        canonical_id = repository_ctx.attr.canonical_id,
        auth = get_auth(repository_ctx, source_urls),
    )

    repository_ctx.report_progress("Extracting dmg.")
    _extract_dmg(
        repository_ctx = repository_ctx,
        zip7_bin = zip7_bin,
        archive = dmg,
        strip_prefix = repository_ctx.attr.strip_prefix,
        add_prefix = repository_ctx.attr.add_prefix,
    )

    # Delete dmg remnants
    repository_ctx.delete(dmg)
    repository_ctx.delete(zip7_dir)

    build_file_content = repository_ctx.attr.build_file_content
    if repository_ctx.attr.build_file:
        build_file_content = repository_ctx.read(repository_ctx.path(repository_ctx.attr.build_file))
    repository_ctx.file("BUILD.bazel", content = build_file_content)

    # TODO: Delete once we drop 8.x
    repository_ctx.file("MODULE.bazel", content = """module(name = "{}")""".format(repository_ctx.name))

    # `patch_strip` is only applied by the `patch` helper from Bazel 8.0, so it
    # is folded into `patch_args` here. On newer versions this yields a repeated
    # `-pN`, of which the last one wins.
    patch(
        repository_ctx,
        patch_args = ["-p{}".format(repository_ctx.attr.patch_strip)] + repository_ctx.attr.patch_args,
    )

    # Return reproducibility attributes
    overrides = {}
    if not repository_ctx.attr.sha256:
        overrides["integrity"] = download_results.integrity

    repro_attrs = update_attrs(repository_ctx.attr, _ATTRS.keys(), overrides)

    # TODO: Delete the fallback once we drop 7.x
    if hasattr(repository_ctx, "repo_metadata"):
        return repository_ctx.repo_metadata(attrs_for_reproducibility = repro_attrs)
    return repro_attrs

def _get_source_urls(url, urls):
    # type: (str, list[str]) -> list[str]
    """Returns the urls provided via the `url` and `urls` attributes."""
    if not url and not urls:
        fail("At least one of url and urls must be provided")

    return [url] + urls if url else urls

_ATTRS = {
    "add_prefix": attr.string(
        default = "",
        doc = """Destination directory relative to the repository directory.

The archive will be unpacked into this directory, after applying `strip_prefix`
(if any) to the file paths within the archive. For example, file
`foo-1.2.3/src/foo.h` will be unpacked to `bar/src/foo.h` if `add_prefix = "bar"`
and `strip_prefix = "foo-1.2.3"`.""",
    ),
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
    "canonical_id": attr.string(
        doc = """A canonical ID of the file downloaded.

If specified and non-empty, Bazel will not take the file from cache, unless it
was added to the cache by a request with the same canonical ID.
""",
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
    "patch_args": attr.string_list(
        default = [],
        doc =
            "The arguments given to the patch tool. Defaults to -p0 (see the `patch_strip` " +
            "attribute), however -p1 will usually be needed for patches generated by " +
            "git. If multiple -p arguments are specified, the last one will take effect." +
            "If arguments other than -p are specified, Bazel will fall back to use patch " +
            "command line tool instead of the Bazel-native patch implementation. When falling " +
            "back to patch command line tool and patch_tool attribute is not specified, " +
            "`patch` will be used. This only affects patch files in the `patches` attribute.",
    ),
    "patch_cmds": attr.string_list(
        default = [],
        doc = "Sequence of Bash commands to be applied on Linux/Macos after patches are applied.",
    ),
    "patch_cmds_win": attr.string_list(
        default = [],
        doc = "Sequence of Powershell commands to be applied on Windows after patches are " +
              "applied. If this attribute is not set, patch_cmds will be executed on Windows, " +
              "which requires Bash binary to exist.",
    ),
    "patch_strip": attr.int(
        default = 0,
        doc = "When set to `N`, this is equivalent to inserting `-pN` to the beginning of `patch_args`.",
    ),
    "patch_tool": attr.string(
        default = "",
        doc = "The patch(1) utility to use. If this is specified, Bazel will use the specified " +
              "patch tool instead of the Bazel-native patch implementation.",
    ),
    "patches": attr.label_list(
        default = [],
        doc =
            "A list of files that are to be applied as patches after " +
            "extracting the archive. By default, it uses the Bazel-native patch implementation " +
            "which doesn't support binary patch, but Bazel will fall back to use " +
            "patch command line tool if `patch_tool` attribute is specified or there are " +
            "arguments other than `-p` in `patch_args` attribute.",
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
directory `foo-lib-1.2.3/` under which there is a `MODULE.bazel` file and are
`src/`, `lib/`, and `test/` directories that contain the actual code you
wish to build. Specify `strip_prefix = "foo-lib-1.2.3"` to use the
`foo-lib-1.2.3` directory as your top-level directory.

Note that if there are files outside of this directory, they will be
discarded and inaccessible (e.g., a top-level license file). This includes
files/directories that start with the prefix but are not in the directory
(e.g., `foo-lib-1.2.3.release-notes`). If the specified prefix does not
match a directory in the archive, Bazel will return an error.""",
    ),
    "url": attr.string(
        doc = """A URL to a file that will be made available to Bazel.

This must be a file, http or https URL. Redirections are followed.
Authentication is not supported.

More flexibility can be achieved by the urls parameter that allows
to specify alternative URLs to fetch from.""",
    ),
    "urls": attr.string_list(
        doc = """A list of URLs to a file that will be made available to Bazel.

Each entry must be a file, http or https URL. Redirections are followed.
Authentication is not supported.

URLs are tried in order until one succeeds, so you should list local mirrors first.
If all downloads fail, the rule will fail.""",
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
