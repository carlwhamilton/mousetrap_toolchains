load("@rules_cc//cc:cc_toolchain_config_lib.bzl", "feature", "flag_group", "flag_set")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")

# Bazel actions involved in pre-processing.
_PREPROCESS_ACTIONS = [
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
]

# Bazel actions involved in compiling C or C++.
_C_ACTIONS = [
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.assemble,
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_link_executable,
]

# Bazel actions involved in compiling only C++.
_CXX_ACTIONS = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_link_executable,
]

# Bazel actions involved in compiling only C.
_CONLY_ACTIONS = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_link_executable,
]

# Bazel actions involved in creating archives.
_ARCHIVE_ACTIONS = [
    ACTION_NAMES.cpp_link_static_library,
]

# Bazel actions involved in linking binaries.
_LINK_ACTIONS = [
    ACTION_NAMES.cpp_link_executable,
]

# Bazel actions that consume libraries.
_LIB_ACTIONS = [
    ACTION_NAMES.cpp_link_executable,
]

# A FeatureGroupInfo is a set of mutually exclusive toolchain
# features.
FeatureGroupInfo = provider(fields = ["name"])

def _toolchain_feature_group_impl(ctx):
    return [FeatureGroupInfo(name = ctx.label.name)]

toolchain_feature_group = rule(
    implementation = _toolchain_feature_group_impl,
    provides = [FeatureGroupInfo],
)

def feature_from_flags(
        name,
        enabled = False,
        group = None,
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
        provides = [group] if group else [],
        flag_sets = [
            flag_set(actions = _PREPROCESS_ACTIONS, flag_groups = preprocess_flags),
            flag_set(actions = _C_ACTIONS, flag_groups = c_flags),
            flag_set(actions = _CXX_ACTIONS, flag_groups = cxx_flags),
            flag_set(actions = _CONLY_ACTIONS, flag_groups = conly_flags),
            flag_set(actions = _ARCHIVE_ACTIONS, flag_groups = archive_flags),
            flag_set(actions = _LINK_ACTIONS, flag_groups = link_flags),
            flag_set(actions = _LIB_ACTIONS, flag_groups = lib_flags),
        ],
    )

# A FeatureSetInfo holds a set of toolchain features. The `features`
# field is a dictionary from toolchain feature label to its associated
# feature.
FeatureSetInfo = provider(fields = ["features"])

def _flags_from_attr(ctx, name, prefix = ""):
    """Returns a list of flag_groups built from a named attribute of `ctx`."""
    flags = [prefix + flag for flag in getattr(ctx.attr, name)]
    return [flag_group(flags = flags)] if flags else []

def _toolchain_feature_impl(ctx):
    feature = feature_from_flags(
        name = ctx.attr.name,
        enabled = ctx.attr.enabled,
        group = ctx.attr.group[FeatureGroupInfo].name if ctx.attr.group else None,
        preprocess_flags = _flags_from_attr(ctx, "defines", "-D"),
        c_flags = _flags_from_attr(ctx, "copts"),
        cxx_flags = _flags_from_attr(ctx, "cxxopts"),
        conly_flags = _flags_from_attr(ctx, "conlyopts"),
        link_flags = _flags_from_attr(ctx, "linkopts"),
        lib_flags = _flags_from_attr(ctx, "libs", "-l"),
    )
    return [FeatureSetInfo(features = {ctx.label: feature})]

toolchain_feature = rule(
    implementation = _toolchain_feature_impl,
    attrs = {
        "enabled": attr.bool(default = False),
        "group": attr.label(providers = [FeatureGroupInfo]),
        "defines": attr.string_list(),
        "copts": attr.string_list(),
        "cxxopts": attr.string_list(),
        "conlyopts": attr.string_list(),
        "linkopts": attr.string_list(),
        "libs": attr.string_list(),
    },
    provides = [FeatureSetInfo],
)

def merge_feature_sets(feature_sets):
    """Returns a a dictionary containing all of the features in `feature_sets`."""
    features = {}
    for feature_set in feature_sets:
        features.update(feature_set[FeatureSetInfo].features)
    return features

def _toolchain_feature_set_impl(ctx):
    features = merge_feature_sets(ctx.attr.deps)
    return FeatureSetInfo(features = features)

toolchain_feature_set = rule(
    implementation = _toolchain_feature_set_impl,
    attrs = {
        "deps": attr.label_list(providers = [FeatureSetInfo]),
    },
    provides = [FeatureSetInfo],
)
