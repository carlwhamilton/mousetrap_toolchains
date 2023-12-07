_ARCHIVE_URL = "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/{prefix}.tar.xz"

def _release(name, platform, sha256, version = None):
    release = struct(
        name = name,
        version = version or name,
        platform = platform,
        sha256 = sha256,
    )
    return (name, release)

_RELEASES = dict([
    _release(
        name = "14.0.0",
        platform = "x86_64-linux-gnu-ubuntu-18.04",
        sha256 = "61582215dafafb7b576ea30cc136be92c877ba1f1c31ddbbd372d6d65622fef5",
    ),
    _release(
        name = "15.0.6",
        platform = "x86_64-linux-gnu-ubuntu-18.04",
        sha256 = "38bc7f5563642e73e69ac5626724e206d6d539fbef653541b34cae0ba9c3f036",
    ),
    _release(
        name = "16.0.0",
        platform = "x86_64-linux-gnu-ubuntu-18.04",
        sha256 = "2b8a69798e8dddeb57a186ecac217a35ea45607cb2b3cf30014431cff4340ad1",
    ),
    _release(
        name = "17.0.6",
        platform = "x86_64-linux-gnu-ubuntu-22.04",
        sha256 = "884ee67d647d77e58740c1e645649e29ae9e8a6fe87c1376be0f3a30f3cc9ab3",
    ),
])

def _find_release(name):
    release = _RELEASES.get(name)
    if not release:
        fail("Failed to find clang release {}".format(name))
    return release

def _get_archive_prefix(release):
    return "clang+llvm-{}-{}".format(release.version, release.platform)

def _get_archive_url(release):
    archive_prefix = _get_archive_prefix(release)
    return _ARCHIVE_URL.format(version = release.version, prefix = archive_prefix)

def _get_build_substitutions(release):
    version = release.version
    major_version = version.split(".")[0]
    return {
        "{version}": version,
        "{major_version}": major_version,
    }

def _clang_repo(repo_ctx):
    release = _find_release(repo_ctx.attr.release)
    repo_ctx.template(
        "BUILD.bazel",
        repo_ctx.attr._build_template,
        _get_build_substitutions(release),
    )
    repo_ctx.download_and_extract(
        url = _get_archive_url(release),
        sha256 = release.sha256,
        stripPrefix = _get_archive_prefix(release),
    )

clang_repo = repository_rule(
    implementation = _clang_repo,
    attrs = {
        "release": attr.string(default = "17.0.6"),
        "_build_template": attr.label(
            default = Label("//clang:clang_BUILD.bazel"),
            allow_single_file = True,
        ),
    },
)
