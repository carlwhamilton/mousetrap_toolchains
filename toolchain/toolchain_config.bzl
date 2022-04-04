load(":toolchain_feature.bzl", "FeatureSetInfo", "feature_from_flags", "merge_feature_sets")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load(
  "@rules_cc//cc:cc_toolchain_config_lib.bzl",
  "ToolInfo",
  "action_config",
  "flag_group",
  "variable_with_value")

def _base_preprocess_flags():
  return [
    flag_group(
      iterate_over = "preprocessor_defines",
      flags = ["-D%{preprocessor_defines}"]),
    flag_group(
      iterate_over = "include_paths",
      flags = ["-I%{include_paths}"]),
    flag_group(
      iterate_over = "quote_include_paths",
      flags = ["-iquote", "%{quote_include_paths}"]),
    flag_group(
      iterate_over = "system_include_paths",
      flags = ["-isystem", "%{system_include_paths}"]),
  ]

def _base_c_flags():
  return [
    flag_group(
      expand_if_available = "source_file",
      flags = ["-c", "%{source_file}"]),
    flag_group(
      expand_if_available = "output_file",
      flags = ["-o", "%{output_file}"]),
    flag_group(
      expand_if_available = "dependency_file",
      flags = ["-MMD", "-MF", "%{dependency_file}"]),
    flag_group(
      expand_if_available = "user_compile_flags",
      iterate_over = "user_compile_flags",
      flags = ["%{user_compile_flags}"]),
  ]

def _base_archive_flags():
  return [
    flag_group(flags = ["rcsD"]),
    flag_group(
      expand_if_available = "output_execpath",
      flags = ["%{output_execpath}"]),
    flag_group(
      iterate_over = "libraries_to_link",
      flags = ["%{libraries_to_link.name}"]),
    flag_group(
      expand_if_available = "linker_param_file",
      flags = ["@%{linker_param_file}"]),
  ]

def _base_link_flags():
  return [
    flag_group(
      expand_if_available = "output_execpath",
      flags = ["-o", "%{output_execpath}"]),
    flag_group(
      iterate_over = "user_link_flags",
      flags = ["%{user_link_flags}"]),
    flag_group(
      expand_if_available = "linker_param_file",
      flags = ["@%{linker_param_file}"]),
  ]

def _base_lib_flags():
  return [
    flag_group(
      iterate_over = "libraries_to_link",
      flag_groups = [
        flag_group(
          expand_if_equal = variable_with_value("libraries_to_link.type", "object_file_group"),
          flags = ["-Wl,--start-lib"],
        ),
        flag_group(
          expand_if_true = "libraries_to_link.is_whole_archive",
          flags = ["-Wl,-whole-archive"]),
        flag_group(
          expand_if_equal = variable_with_value("libraries_to_link.type", "object_file_group"),
          iterate_over = "libraries_to_link.object_files",
          flags = ["%{libraries_to_link.object_files}"],
        ),
        flag_group(
          expand_if_equal = variable_with_value("libraries_to_link.type", "object_file"),
          flags = ["%{libraries_to_link.name}"]),
        flag_group(
          expand_if_equal = variable_with_value("libraries_to_link.type", "static_library"),
          flags = ["%{libraries_to_link.name}"]),
        flag_group(
          expand_if_true = "libraries_to_link.is_whole_archive",
          flags = ["-Wl,-no-whole-archive"]),
        flag_group(
          expand_if_equal = variable_with_value("libraries_to_link.type", "object_file_group"),
          flags = ["-Wl,--end-lib"],
        ),
      ]),
  ]

def _base_feature():
  return feature_from_flags(
    name = "base",
    enabled = True,
    preprocess_flags = _base_preprocess_flags(),
    c_flags = _base_c_flags(),
    archive_flags = _base_archive_flags(),
    link_flags = _base_link_flags(),
    lib_flags = _base_lib_flags())

def _toolchain_tool(ctx, name):
  for tool in ctx.attr.tools:
    if tool.label.name == name:
      return tool[ToolInfo]
  fail("Failed to find {} tool".format(name))

def _toolchain_action(action, tool):
  return action_config(action, tools = [tool])

def _toolchain_config(ctx):
  cc = _toolchain_tool(ctx, "cc")
  cxx = _toolchain_tool(ctx, "cxx")
  ar = _toolchain_tool(ctx, "ar")
  strip = _toolchain_tool(ctx, "strip")

  action_configs = [
    _toolchain_action(ACTION_NAMES.preprocess_assemble, cc),
    _toolchain_action(ACTION_NAMES.c_compile, cc),
    _toolchain_action(ACTION_NAMES.cpp_compile, cxx),
    _toolchain_action(ACTION_NAMES.cpp_link_static_library, ar),
    _toolchain_action(ACTION_NAMES.cpp_link_executable, cxx),
    _toolchain_action(ACTION_NAMES.strip, strip),
  ]

  all_features = merge_feature_sets(ctx.attr.all_features)
  features = [_base_feature()] + all_features.values()

  host_system_name = "x86_64-unknown-linux-gnu"
  target_cpu = ctx.attr.target_cpu
  target_platform = ctx.attr.target_platform
  target_libc = ctx.attr.target_libc
  compiler = ctx.attr.compiler
  return cc_common.create_cc_toolchain_config_info(
    ctx = ctx,
    toolchain_identifier = "%s-%s-%s" % (target_cpu, target_platform, compiler),
    host_system_name = host_system_name,
    target_system_name = host_system_name,
    target_cpu = target_cpu,
    target_libc = target_libc,
    compiler = compiler,
    abi_version = "",
    abi_libc_version = "",
    action_configs = action_configs,
    features = features,
    cxx_builtin_include_directories = ctx.attr.system_includes)

toolchain_config = rule(
  implementation = _toolchain_config,
  attrs = {
    "compiler": attr.string(default = "clang"),
    "target_cpu": attr.string(default = "k8"),
    "target_platform": attr.string(default = "linux"),
    "target_libc": attr.string(default = "libc"),
    "tools": attr.label_list(providers = [ToolInfo]),
    "all_features": attr.label_list(providers=[FeatureSetInfo]),
    "system_includes": attr.string_list(default = []),
  },
  provides = [CcToolchainConfigInfo])
