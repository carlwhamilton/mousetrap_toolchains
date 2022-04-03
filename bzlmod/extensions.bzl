load("//clang:clang_repo.bzl", "clang_repo")

release = tag_class(
  attrs = {
    "name": attr.string(mandatory = True),
  }
)

def _get_release_name(release_name, releases):
  for release in releases:
    if not release_name:
      release_name = release.name
    if release_name != release.name:
      fail("Conflicting releases: {} and {}".format(release_name, release.name))
  return release_name

def _clang(module_ctx):
  release_name = None
  for module in module_ctx.modules:
    release_name = _get_release_name(release_name, module.tags.release)
  clang_repo(name = "clang", release = release_name)

clang = module_extension(
  implementation = _clang,
  tag_classes = {
    "release": release,
  },
)
