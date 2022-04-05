load("@mousetrap_toolchains//toolchain:toolchain_config.bzl", "toolchain_config")

def clang_toolchain(name, target_cpu, target_os, tools, all_features):
  toolchain_config_name = "%s_config" % name
  toolchain_config(
    name = toolchain_config_name,
    compiler = "@mousetrap_toolchains//compiler:clang",
    target_cpu = target_cpu,
    target_os = target_os,
    target_libc = "glibc",
    tools = tools,
    all_features = all_features,
    system_includes = ["/usr/include"])

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
      target_cpu,
      target_os,
    ],
    toolchain = cc_toolchain_name,
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    visibility = ["//visibility:public"],
    tags = ["manual"])
