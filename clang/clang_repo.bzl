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
    name = "13.0.0",
    platform = "x86_64-linux-gnu-ubuntu-20.04",
    sha256 = "2c2fb857af97f41a5032e9ecadf7f78d3eff389a5cd3c9ec620d24f134ceb3c8"),
  _release(
    name = "14.0.0",
    platform = "x86_64-linux-gnu-ubuntu-18.04",
    sha256 = "61582215dafafb7b576ea30cc136be92c877ba1f1c31ddbbd372d6d65622fef5"),
])

def _get_release(name):
  release = _RELEASES.get(name)
  if not release:
    fail("Failed to find clang release {}".format(name))
  return release

def _release_prefix(release):
  return "clang+llvm-%s-%s" % (release.version, release.platform)

def _release_url(release):
  archive_prefix = _release_prefix(release)
  return "https://github.com/llvm/llvm-project/releases/download/llvmorg-%s/%s.tar.xz" % (release.version, archive_prefix)

def _release_substitutions(release):
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
    _release_substitutions(release))
  repo_ctx.report_progress("Preparing clang {} toolchain".format(release.name))
  repo_ctx.download_and_extract(
    url = _release_url(release),
    sha256 = release.sha256,
    stripPrefix = _release_prefix(release))

clang_repo = repository_rule(
  implementation = _clang_repo,
  attrs = {
    "release": attr.string(default = "13.0.0"),
    "_build_template": attr.label(
      default = Label("//clang:clang_BUILD.bazel"),
      allow_single_file = True)
  }
)
