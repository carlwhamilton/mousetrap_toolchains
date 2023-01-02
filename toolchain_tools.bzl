load("@rules_cc//cc:cc_toolchain_config_lib.bzl", "ToolInfo", "tool")

def _toolchain_tool_impl(ctx):
    executable = ctx.executable.executable
    files = depset([executable], transitive = [dep[DefaultInfo].files for dep in ctx.attr.deps])
    return [tool(path = executable.short_path), DefaultInfo(files = files)]

toolchain_tool = rule(
    implementation = _toolchain_tool_impl,
    attrs = {
        "executable": attr.label(mandatory = True, executable = True, cfg = "exec", allow_single_file = True),
        "deps": attr.label_list(allow_files = True),
    },
    provides = [ToolInfo, DefaultInfo],
)
