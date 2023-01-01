load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "ToolInfo",
    "action_config",
    "feature",
    "flag_group",
    "flag_set",
    "variable_with_value",
)

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
            flag_set(actions = _PREPROCESS_ACTIONS, flag_groups = preprocess_flags),
            flag_set(actions = _C_ACTIONS, flag_groups = c_flags),
            flag_set(actions = _CXX_ACTIONS, flag_groups = cxx_flags),
            flag_set(actions = _CONLY_ACTIONS, flag_groups = conly_flags),
            flag_set(actions = _ARCHIVE_ACTIONS, flag_groups = archive_flags),
            flag_set(actions = _LINK_ACTIONS, flag_groups = link_flags),
            flag_set(actions = _LIB_ACTIONS, flag_groups = lib_flags),
        ],
    )

# The `features` field is a dictionary from label to its associated
# FeatureInfo.
FeatureSetInfo = provider(fields = ["features"])

def merge_feature_sets(feature_sets):
    """Returns a a dictionary containing all of the features in `feature_sets`."""
    return dicts.add(*[feature_set[FeatureSetInfo].features for feature_set in feature_sets])

def _base_preprocess_flags():
    """Returns the list of base preprocessor flag_groups."""
    return [
        flag_group(
            iterate_over = "preprocessor_defines",
            flags = ["-D%{preprocessor_defines}"],
        ),
        flag_group(
            iterate_over = "include_paths",
            flags = ["-I%{include_paths}"],
        ),
        flag_group(
            iterate_over = "quote_include_paths",
            flags = ["-iquote", "%{quote_include_paths}"],
        ),
        flag_group(
            iterate_over = "system_include_paths",
            flags = ["-isystem", "%{system_include_paths}"],
        ),
    ]

def _base_c_flags():
    """Returns the list of base C or C++ compiler flag_groups."""
    return [
        flag_group(
            expand_if_available = "source_file",
            flags = ["-c", "%{source_file}"],
        ),
        flag_group(
            expand_if_available = "output_file",
            flags = ["-o", "%{output_file}"],
        ),
        flag_group(
            expand_if_available = "dependency_file",
            flags = ["-MMD", "-MF", "%{dependency_file}"],
        ),
        flag_group(
            expand_if_available = "user_compile_flags",
            iterate_over = "user_compile_flags",
            flags = ["%{user_compile_flags}"],
        ),
    ]

def _base_archive_flags():
    """Returns the list of base archive flag_groups."""
    return [
        flag_group(flags = ["rcsD"]),
        flag_group(
            expand_if_available = "output_execpath",
            flags = ["%{output_execpath}"],
        ),
        flag_group(
            iterate_over = "libraries_to_link",
            flags = ["%{libraries_to_link.name}"],
        ),
        flag_group(
            expand_if_available = "linker_param_file",
            flags = ["@%{linker_param_file}"],
        ),
    ]

def _base_link_flags():
    """Returns the list of base linker flag_groups."""
    return [
        flag_group(
            expand_if_available = "output_execpath",
            flags = ["-o", "%{output_execpath}"],
        ),
        flag_group(
            iterate_over = "user_link_flags",
            flags = ["%{user_link_flags}"],
        ),
        flag_group(
            expand_if_available = "linker_param_file",
            flags = ["@%{linker_param_file}"],
        ),
    ]

def _base_lib_flags():
    """Returns the list of base library flag_groups."""
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
                    flags = ["-Wl,-whole-archive"],
                ),
                flag_group(
                    expand_if_equal = variable_with_value("libraries_to_link.type", "object_file_group"),
                    iterate_over = "libraries_to_link.object_files",
                    flags = ["%{libraries_to_link.object_files}"],
                ),
                flag_group(
                    expand_if_equal = variable_with_value("libraries_to_link.type", "object_file"),
                    flags = ["%{libraries_to_link.name}"],
                ),
                flag_group(
                    expand_if_equal = variable_with_value("libraries_to_link.type", "static_library"),
                    flags = ["%{libraries_to_link.name}"],
                ),
                flag_group(
                    expand_if_true = "libraries_to_link.is_whole_archive",
                    flags = ["-Wl,-no-whole-archive"],
                ),
                flag_group(
                    expand_if_equal = variable_with_value("libraries_to_link.type", "object_file_group"),
                    flags = ["-Wl,--end-lib"],
                ),
            ],
        ),
    ]

def _base_feature():
    """Returns the base feature."""
    return feature_from_flags(
        name = "base",
        enabled = True,
        preprocess_flags = _base_preprocess_flags(),
        c_flags = _base_c_flags(),
        archive_flags = _base_archive_flags(),
        link_flags = _base_link_flags(),
        lib_flags = _base_lib_flags(),
    )

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

    compiler = ctx.attr.compiler.label.name
    target_cpu = ctx.attr.target_cpu.label.name
    target_os = ctx.attr.target_os.label.name
    target_system_name = "%s-%s" % (target_cpu, target_os)

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "%s-%s" % (compiler, target_system_name),
        compiler = compiler,
        target_cpu = target_cpu,
        target_libc = ctx.attr.target_libc,
        target_system_name = target_system_name,
        action_configs = action_configs,
        features = features,
        cxx_builtin_include_directories = ctx.attr.system_includes,
    )

toolchain_config = rule(
    implementation = _toolchain_config,
    attrs = {
        "compiler": attr.label(mandatory = True, providers = [platform_common.ConstraintValueInfo]),
        "target_cpu": attr.label(mandatory = True, providers = [platform_common.ConstraintValueInfo]),
        "target_os": attr.label(mandatory = True, providers = [platform_common.ConstraintValueInfo]),
        "target_libc": attr.string(mandatory = True),
        "tools": attr.label_list(providers = [ToolInfo]),
        "all_features": attr.label_list(providers = [FeatureSetInfo]),
        "system_includes": attr.string_list(default = []),
    },
    provides = [CcToolchainConfigInfo],
)
