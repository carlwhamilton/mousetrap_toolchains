load("//clang:clang_repo.bzl", "clang_repo")

def _clang(module_ctx):
  clang_repo(name = "clang", release = "13.0.0")

clang = module_extension(
  implementation = _clang,
  tag_classes = {
  },
)
