def linker_script(name, script, deps = [], linkopts = [], **kwargs):
  native.cc_library(
    name = name,
    deps = deps + [
      script
    ],
    linkopts = linkopts + [
      "-T $(location {script})".format(script = script),
    ],
    **kwargs,
  )
