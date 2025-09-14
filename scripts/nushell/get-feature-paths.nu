#!/usr/bin/env nu
# Nushell port of bash/get-feature-paths.sh
use ./common.nu *

export def main [] {
  let paths = (get_feature_paths)
  let branch = $paths.CURRENT_BRANCH
  try { check_feature_branch $branch } catch {|err| print $err.msg; exit 1 }
  print $"REPO_ROOT: ($paths.REPO_ROOT)"
  print $"BRANCH: ($branch)"
  print $"FEATURE_DIR: ($paths.FEATURE_DIR)"
  print $"FEATURE_SPEC: ($paths.FEATURE_SPEC)"
  print $"IMPL_PLAN: ($paths.IMPL_PLAN)"
  print $"TASKS: ($paths.TASKS)"
}

main
