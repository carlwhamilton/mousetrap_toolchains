_GITHUB_ARCHIVE_URL = "https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}/{prefix}.tar.xz"

def _release(name, platform, sha256, version = None, archive_prefix = None):
  release = struct(
    name = name,
    version = version or name,
    platform = platform,
    sha256 = sha256,
    archive_prefix = archive_prefix)
  return (name, release)

_RELEASES = dict([
  _release(
    name = "14.0.0",
    platform = "x86_64-linux-gnu-ubuntu-18.04",
    sha256 = "61582215dafafb7b576ea30cc136be92c877ba1f1c31ddbbd372d6d65622fef5"),
])

def _get_release(name):
  release = _RELEASES.get(name)
  if not release:
    fail("Failed to find clang release {release}".format(release = name))
  return release

def _archive_prefix(release):
  return "clang+llvm-{version}-{platform}".format(version = release.version, platform = release.platform)

def _archive_url(release):
  archive_prefix = _archive_prefix(release)
  return _GITHUB_ARCHIVE_URL.format(version = release.version, prefix = archive_prefix)

def _build_substitutions(release):
  version = release.version
  major_version = version.split(".")[0]
  return {
    "{version}": version,
    "{major_version}": major_version,
  }

def _clang_repo(repo_ctx):
  release = _get_release(repo_ctx.attr.release)
  repo_ctx.template(
    "BUILD.bazel",
    repo_ctx.attr._build_template,
    _build_substitutions(release))
  repo_ctx.download_and_extract(
    url = _archive_url(release),
    sha256 = release.sha256,
    stripPrefix = _archive_prefix(release))

clang_repo = repository_rule(
  implementation = _clang_repo,
  attrs = {
    "release": attr.string(default = "14.0.0"),
    "_build_template": attr.label(
      default = Label("//clang:clang_BUILD.bazel"),
      allow_single_file = True)
  }
)
