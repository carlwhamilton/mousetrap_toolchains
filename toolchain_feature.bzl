load(
    ":toolchain_config.bzl",
    "FeatureSetInfo",
    "feature_from_flags",
    "merge_feature_sets",
)
load("@rules_cc//cc:cc_toolchain_config_lib.bzl", "flag_group")

FeatureGroupInfo = provider(fields = ["name"])

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
        lib_flags = _flags_from_attr(ctx, "libs", "-l"),
    )
    return [FeatureSetInfo(features = {ctx.label: feature})]

toolchain_feature = rule(
    implementation = _toolchain_feature,
    attrs = {
        "enabled": attr.bool(default = False),
        "defines": attr.string_list(),
        "copts": attr.string_list(),
        "cxxopts": attr.string_list(),
        "conlyopts": attr.string_list(),
        "linkopts": attr.string_list(),
        "libs": attr.string_list(),
        "group": attr.label(providers = [FeatureGroupInfo]),
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
        "deps": attr.label_list(providers = [FeatureSetInfo]),
    },
    provides = [FeatureSetInfo],
)
