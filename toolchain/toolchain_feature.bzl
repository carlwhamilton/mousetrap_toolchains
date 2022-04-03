load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load(
  "@rules_cc//cc:cc_toolchain_config_lib.bzl",
  "feature",
  "flag_group",
  "flag_set")

FeatureGroupInfo = provider(fields = ["name"])

# features is a dictionary from a label to its associated FeatureInfo.
FeatureSetInfo = provider(fields = ["features"])

_PREPROCESS_FLAGS_ACTIONS = [
  ACTION_NAMES.preprocess_assemble,
  ACTION_NAMES.c_compile,
  ACTION_NAMES.cpp_compile,
]

_C_FLAGS_ACTIONS = [
  ACTION_NAMES.preprocess_assemble,
  ACTION_NAMES.assemble,
  ACTION_NAMES.c_compile,
  ACTION_NAMES.cpp_compile,
  ACTION_NAMES.cpp_link_executable,
]

_CXX_FLAGS_ACTIONS = [
  ACTION_NAMES.cpp_compile,
  ACTION_NAMES.cpp_link_executable,
]

_CONLY_FLAGS_ACTIONS = [
  ACTION_NAMES.c_compile,
  ACTION_NAMES.cpp_link_executable,
]

_ARCHIVE_FLAGS_ACTIONS = [
  ACTION_NAMES.cpp_link_static_library,
]

_LINK_FLAGS_ACTIONS = [
  ACTION_NAMES.cpp_link_executable,
]

_LIB_FLAGS_ACTIONS = [
  ACTION_NAMES.cpp_link_executable,
]

def feature_from_flags(
    name,
    enabled = False,
    provides = [],
    preprocess_flags = [],
    c_flags = [],
    cxx_flags = [],
    conly_flags = [],
    archive_flags = [],
    link_flags = [],
    lib_flags = []):
  """Returns a feature constructed from the given lists of flag_groups.""" 
  return feature(
    name = name,
    enabled = enabled,
    provides = provides,
    flag_sets = [
      flag_set(actions = _PREPROCESS_FLAGS_ACTIONS, flag_groups = preprocess_flags),
      flag_set(actions = _C_FLAGS_ACTIONS, flag_groups = c_flags),
      flag_set(actions = _CXX_FLAGS_ACTIONS, flag_groups = cxx_flags),
      flag_set(actions = _CONLY_FLAGS_ACTIONS, flag_groups = conly_flags),
      flag_set(actions = _ARCHIVE_FLAGS_ACTIONS, flag_groups = archive_flags),
      flag_set(actions = _LINK_FLAGS_ACTIONS, flag_groups = link_flags),
      flag_set(actions = _LIB_FLAGS_ACTIONS, flag_groups = lib_flags),
    ])

def merge_feature_sets(feature_sets):
  return dicts.add(*[feature_set[FeatureSetInfo].features for feature_set in feature_sets])

def _flags_from_attr(ctx, name, prefix = ""):
  flags = [prefix + flag for flag in getattr(ctx.attr, name)]
  return [flag_group(flags = flags)] if flags else []

def _toolchain_feature(ctx):
  feature = feature_from_flags(
    name = ctx.attr.name,
    enabled = ctx.attr.enabled,
    provides = [ctx.attr.group[FeatureGroupInfo].name] if ctx.attr.group else [],
    preprocess_flags = _flags_from_attr(ctx, "defines", "-D"),
    c_flags = _flags_from_attr(ctx, "copts"),
    cxx_flags = _flags_from_attr(ctx, "cxxopts"),
    conly_flags = _flags_from_attr(ctx, "conlyopts"),
    link_flags = _flags_from_attr(ctx, "linkopts"),
    lib_flags = _flags_from_attr(ctx, "libs", "-l"))
  return [FeatureSetInfo(features = {ctx.label: feature})]

toolchain_feature = rule(
  implementation = _toolchain_feature,
  attrs = {
    "enabled": attr.bool(default=False),
    "defines": attr.string_list(),
    "copts": attr.string_list(),
    "cxxopts": attr.string_list(),
    "conlyopts": attr.string_list(),
    "linkopts": attr.string_list(),
    "libs": attr.string_list(),
    "group": attr.label(providers=[FeatureGroupInfo]),
  },
  provides = [FeatureSetInfo],
)

def _toolchain_feature_group(ctx):
  return [FeatureGroupInfo(name = ctx.label.name)]

toolchain_feature_group = rule(
  implementation = _toolchain_feature_group,
  provides = [FeatureGroupInfo],
)

def _toolchain_feature_set(ctx):
  features = merge_feature_sets(ctx.attr.deps)
  return FeatureSetInfo(features = features)

toolchain_feature_set = rule(
  implementation = _toolchain_feature_set,
  attrs = {
    "deps": attr.label_list(providers=[FeatureSetInfo]),
  },
  provides = [FeatureSetInfo],
)

