#!/usr/bin/env nu
# Nushell port of bash/check-task-prerequisites.sh
use ./common.nu *

export def main [...args] {
  mut json_mode = false
  for a in $args { if $a in ['--json'] { $json_mode = true } else if $a in ['--help' '-h'] { print 'Usage: check-task-prerequisites.nu [--json]'; return } }

  let paths = (get_feature_paths)
  try { check_feature_branch $paths.CURRENT_BRANCH } catch {|err| print $err.msg; exit 1 }
  if not ($paths.FEATURE_DIR | path exists) { print $"ERROR: Feature directory not found: ($paths.FEATURE_DIR)\nRun /specify first."; exit 1 }
  if not ($paths.IMPL_PLAN | path exists) { print $"ERROR: plan.md not found in ($paths.FEATURE_DIR)\nRun /plan first."; exit 1 }

  if $json_mode {
    mut docs = []
    if ($paths.RESEARCH | path exists) { $docs ++= ['research.md'] }
    if ($paths.DATA_MODEL | path exists) { $docs ++= ['data-model.md'] }
    if ($paths.CONTRACTS_DIR | path exists) and ((ls $paths.CONTRACTS_DIR | length) > 0) { $docs ++= ['contracts/'] }
    if ($paths.QUICKSTART | path exists) { $docs ++= ['quickstart.md'] }
    { FEATURE_DIR: $paths.FEATURE_DIR AVAILABLE_DOCS: $docs } | to json -r
  } else {
    print $"FEATURE_DIR:($paths.FEATURE_DIR)"
    print 'AVAILABLE_DOCS:'
    print (check_file $paths.RESEARCH 'research.md')
    print (check_file $paths.DATA_MODEL 'data-model.md')
    print (check_dir $paths.CONTRACTS_DIR 'contracts/')
    print (check_file $paths.QUICKSTART 'quickstart.md')
  }
}

main
