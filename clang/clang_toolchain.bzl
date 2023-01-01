load("@mousetrap_toolchains//:toolchain_config.bzl", "toolchain_config")

def clang_cc_toolchain(name, target_cpu, target_os, all_features):
    toolchain_config_name = "%s_config" % name
    toolchain_config(
        name = toolchain_config_name,
        compiler = "@mousetrap_toolchains//compiler:clang",
        target_cpu = target_cpu,
        target_os = target_os,
        target_libc = "glibc",
        all_features = all_features,
        tools = [
            ":cc",
            ":cxx",
            ":ar",
            ":strip",
        ],
        system_includes = ["/usr/include"],
    )

    native.cc_toolchain(
        name = name,
        toolchain_config = toolchain_config_name,
        all_files = ":all_files",
        compiler_files = ":compiler_files",
        ar_files = ":ar_files",
        linker_files = ":linker_files",
        objcopy_files = ":objcopy_files",
        strip_files = ":strip_files",
        dwp_files = ":dwp_files",
        supports_param_files = True,
    )

def clang_toolchain(name, target_cpu, target_os):
    native.toolchain(
        name = name,
        target_compatible_with = [
            target_cpu,
            target_os,
        ],
        toolchain = "@clang//:{name}".format(name = name),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
        tags = ["manual"],
    )
