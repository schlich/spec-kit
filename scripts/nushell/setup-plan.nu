#!/usr/bin/env nu
# Nushell port of bash/setup-plan.sh
use ./common.nu *

export def main [...args] {
  mut json_mode = false
  for a in $args { if $a in ['--json'] { $json_mode = true } else if $a in ['--help' '-h'] { print 'Usage: setup-plan.nu [--json]'; return } }

  let paths = (get_feature_paths)
  try { check_feature_branch $paths.CURRENT_BRANCH } catch {|err| print $err.msg; exit 1 }
  mkdir $paths.FEATURE_DIR

  # Template path (keeping legacy bash path fallback .specify/templates)
  let template_primary = $"($paths.REPO_ROOT)/.specify/templates/plan-template.md"
  let template_alt = $"($paths.REPO_ROOT)/templates/plan-template.md"
  if ($template_primary | path exists) {
    cp $template_primary $paths.IMPL_PLAN
  } else if ($template_alt | path exists) {
    cp $template_alt $paths.IMPL_PLAN
  } else {
    touch $paths.IMPL_PLAN
  }

  if $json_mode {
    { FEATURE_SPEC: $paths.FEATURE_SPEC IMPL_PLAN: $paths.IMPL_PLAN SPECS_DIR: $paths.FEATURE_DIR BRANCH: $paths.CURRENT_BRANCH } | to json -r
  } else {
    print $"FEATURE_SPEC: ($paths.FEATURE_SPEC)"; print $"IMPL_PLAN: ($paths.IMPL_PLAN)"; print $"SPECS_DIR: ($paths.FEATURE_DIR)"; print $"BRANCH: ($paths.CURRENT_BRANCH)"
  }
}

main
