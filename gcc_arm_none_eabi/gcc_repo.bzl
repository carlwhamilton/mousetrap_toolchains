_ARM_ARCHIVE_URL = "https://developer.arm.com/-/media/Files/downloads/gnu-rm/{release}/gcc-arm-none-eabi-{release}-{platform}.tar.bz2"

def _release(name, version, platform, sha256):
  release = struct(
    name = name,
    version = version,
    platform = platform,
    sha256 = sha256)
  return (name, release)

_RELEASES = dict([
  _release(
    name = "10.3-2021.10",
    version = "10.3.1",
    platform = "x86_64-linux",
    sha256 = "97dbb4f019ad1650b732faffcc881689cedc14e2b7ee863d390e0a41ef16c9a3",
  ),
])

def _get_release(name):
  release = _RELEASES.get(name)
  if not release:
    fail("Failed to find gcc-arm-none-eabi release {release}".format(release = name))
  return release

def _archive_prefix(release):
  return "gcc-arm-none-eabi-{release}".format(release = release.name)

def _archive_url(release):
  return _ARM_ARCHIVE_URL.format(release = release.name, platform = release.platform)

def _build_substitutions(release):
  return {
    "{version}": release.version,
  }

def _gcc_repo(repo_ctx):
  release = _get_release(repo_ctx.attr.release)
  repo_ctx.template(
    "BUILD.bazel",
    repo_ctx.attr._build_template,
    _build_substitutions(release))
  repo_ctx.download_and_extract(
    url = _archive_url(release),
    sha256 = release.sha256,
    stripPrefix = _archive_prefix(release))

gcc_repo = repository_rule(
  implementation = _gcc_repo,
  attrs = {
    "release": attr.string(default = "10.3-2021.10"),
    "_build_template": attr.label(
      default = Label("//gcc_arm_none_eabi:gcc_BUILD.bazel"),
      allow_single_file = True)
  }
)
