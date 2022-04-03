load("@mousetrap_toolchains//toolchain:toolchain_config.bzl", "toolchain_config")

def clang_toolchain(name, all_features):
  toolchain_config_name = "%s_config" % name
  toolchain_config(
    name = toolchain_config_name,
    cc = ":cc",
    cxx = ":cxx",
    ar = ":ar",
    strip = ":strip",
    all_features = all_features,
    system_includes = ["/usr/include"],
    supports_start_end_lib = True)

  cc_toolchain_name = "%s_cc_toolchain" % name
  native.cc_toolchain(
    name = cc_toolchain_name,
    toolchain_config = toolchain_config_name,
    all_files = ":all_files",
    compiler_files = ":compiler_files",
    ar_files = ":ar_files",
    linker_files = ":linker_files",
    objcopy_files = ":objcopy_files",
    strip_files = ":strip_files",
    dwp_files = ":dwp_files",
    supports_param_files = True)

  native.toolchain(
    name = name,
    exec_compatible_with = [
      "@platforms//cpu:x86_64",
      "@platforms//os:linux",
    ],
    target_compatible_with = [
      "@platforms//cpu:x86_64",
      "@platforms//os:linux",
    ],
    toolchain = cc_toolchain_name,
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    visibility = ["//visibility:public"],
    tags = ["manual"])
