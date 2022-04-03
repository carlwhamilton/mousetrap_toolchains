_GITHUB_RELEASE_URL = "https://github.com/llvm/llvm-project/releases/download/llvmorg-{release}/clang+llvm-{release}-x86_64-linux-gnu-ubuntu-20.04.tar.xz"

def _release_info(release, platform, sha256, archive_prefix = None):
  return struct(
    release = release,
    version = release,
    platform = platform,
    sha256 = sha256,
    archive_prefix = archive_prefix)

_RELEASE_INFO = [
  _release_info(
    release = "13.0.0",
    platform = "x86_64-linux-gnu-ubuntu-20.04",
    sha256 = "2c2fb857af97f41a5032e9ecadf7f78d3eff389a5cd3c9ec620d24f134ceb3c8"),
]

def _get_release_info(release):
  for info in _RELEASE_INFO:
    if info.release == release:
      return info
  fail("Failed to find clang release", release)

def _release_prefix(info):
  return "clang+llvm-%s-%s" % (info.version, info.platform)
  
def _release_url(info):
  archive_prefix = _release_prefix(info)
  return "https://github.com/llvm/llvm-project/releases/download/llvmorg-%s/%s.tar.xz" % (info.version, archive_prefix)
    
def _release_substitutions(info):
  version = info.version
  major_version = version.split(".")[0]
  return {
    "{version}": version,
    "{major_version}": major_version,
  }

def _clang_repo(repo_ctx):
  info = _get_release_info(repo_ctx.attr.release)
  repo_ctx.template(
    "BUILD.bazel",
    repo_ctx.attr._build_template,
    _release_substitutions(info))
  repo_ctx.download_and_extract(
    url = _release_url(info),
    sha256 = info.sha256,
    stripPrefix = _release_prefix(info))
    
clang_repo = repository_rule(
  implementation = _clang_repo,
  attrs = {
    "release": attr.string(mandatory=True),
    "_build_template": attr.label(
      default=Label("//clang:clang_BUILD.bazel"),
      allow_single_file=True)
  }
)
