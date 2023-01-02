_ARM_ARCHIVE_URL = "https://developer.arm.com/-/media/Files/downloads/gnu/{name}/binrel/arm-gnu-toolchain-{name}-{platform}-arm-none-eabi.tar.xz"

def _release(name, version, platform, sha256):
    release = struct(
        name = name,
        version = version,
        platform = platform,
        sha256 = sha256,
    )
    return (name, release)

_RELEASES = dict([
    _release(
        name = "12.2.rel1",
        version = "12.2.1",
        platform = "x86_64",
        sha256 = "84be93d0f9e96a15addd490b6e237f588c641c8afdf90e7610a628007fc96867",
    ),
])

def _find_release(name):
    release = _RELEASES.get(name)
    if not release:
        fail("Failed to find gcc-arm-none-eabi release {}".format(name))
    return release

def _archive_prefix(release):
    return "arm-gnu-toolchain-{}-{}-arm-none-eabi".format(release.name, release.platform)

def _archive_url(release):
    return _ARM_ARCHIVE_URL.format(name = release.name, platform = release.platform)

def _build_substitutions(release):
    return {
        "{version}": release.version,
    }

def _gcc_repo(repo_ctx):
    release = _find_release(repo_ctx.attr.release)
    repo_ctx.template(
        "BUILD.bazel",
        repo_ctx.attr._build_template,
        _build_substitutions(release),
    )
    repo_ctx.download_and_extract(
        url = _archive_url(release),
        sha256 = release.sha256,
        stripPrefix = _archive_prefix(release),
    )

gcc_repo = repository_rule(
    implementation = _gcc_repo,
    attrs = {
        "release": attr.string(default = "12.2.rel1"),
        "_build_template": attr.label(
            default = Label("//gcc_arm_none_eabi:gcc_BUILD.bazel"),
            allow_single_file = True,
        ),
    },
)
