_PROVIDERS = {
  "ConstraintSettingInfo": platform_common.ConstraintSettingInfo,
  "ConstraintValueInfo": platform_common.ConstraintValueInfo,
  "PlatformInfo": platform_common.PlatformInfo,
  "OutputGroupInfo": OutputGroupInfo,
  "DefaultInfo": DefaultInfo,
}

def _dump_target(ctx):
  target = ctx.attr.target
  label = target.label
  print("%s:" % label, target)
  for name, provider in _PROVIDERS.items():
    if provider in target:
      print("%s[%s]:" % (label, name), target[provider])

dump_target = rule(
  implementation = _dump_target,
  attrs = {
    "target": attr.label(mandatory = True),
  },
)
