#!/usr/bin/env nu
# Common Nushell utilities mirroring bash/common.sh

export def get_repo_root [] {
  git rev-parse --show-toplevel | str trim
}

export def get_current_branch [] {
  git rev-parse --abbrev-ref HEAD | str trim
}

# Returns error (non-zero) if not a feature branch (expects NNN- prefix)
export def check_feature_branch [branch:string] {
  if not ($branch =~ '^[0-9]{3}-') {
    error make { msg: $"ERROR: Not on a feature branch. Current branch: ($branch)\nFeature branches should be named like: 001-feature-name" }
  }
  $branch
}

export def get_feature_dir [repo_root:string branch:string] {
  $"($repo_root)/specs/($branch)"
}

# Emit record of common feature paths
export def get_feature_paths [] {
  let repo_root = (get_repo_root)
  let current_branch = (get_current_branch)
  let feature_dir = (get_feature_dir $repo_root $current_branch)
  {
    REPO_ROOT: $repo_root
    CURRENT_BRANCH: $current_branch
    FEATURE_DIR: $feature_dir
    FEATURE_SPEC: $"($feature_dir)/spec.md"
    IMPL_PLAN: $"($feature_dir)/plan.md"
    TASKS: $"($feature_dir)/tasks.md"
    RESEARCH: $"($feature_dir)/research.md"
    DATA_MODEL: $"($feature_dir)/data-model.md"
    QUICKSTART: $"($feature_dir)/quickstart.md"
    CONTRACTS_DIR: $"($feature_dir)/contracts"
  }
}

# Helpers to indicate presence of file/dir
export def check_file [path:string label:string] {
  if ($path | path exists) {
    $"  ✓ ($label)"
  } else { $"  ✗ ($label)" }
}

export def check_dir [path:string label:string] {
  if ($path | path exists) and ($path | path type) == 'dir' and ((ls $path | length) > 0) {
    $"  ✓ ($label)"
  } else { $"  ✗ ($label)" }
}
