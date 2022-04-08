def linker_script(name, script, hdrs = []):
  native.cc_library(
    name = name,
    hdrs = hdrs,
    deps = [script],
    linkopts = [
      "-T $(location {script})".format(script = script),
    ],
  )
