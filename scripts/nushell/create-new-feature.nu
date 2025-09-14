#!/usr/bin/env nu
# Create a new feature (Nushell port of bash/create-new-feature.sh)

use ./common.nu *

def help [] { print 'Usage: create-new-feature.nu [--json] <feature description>'; }

export def main [...args] {
  mut json_mode = false
  mut parts = []
  for a in $args {
    match $a {
      '--json' => { $json_mode = true }
      '--help' | '-h' => { help; return }
      _ => { $parts ++= [$a] }
    }
  }
  let feature_description = ($parts | str join ' ' | str trim)
  if ($feature_description | is-empty) { help; error make { msg: 'Feature description required' } }

  let repo_root = (get_repo_root)
  let specs_dir = $"($repo_root)/specs"
  mkdir $specs_dir

  # determine highest existing NNN prefix
  let existing_numbers = (ls $specs_dir | where type == 'dir' | get name | path basename | parse -r '^(?P<num>[0-9]+)-' | default {num: []} | get num | each { |n| $n | into int } )
  let highest = (if ($existing_numbers | is-empty) {0} else { $existing_numbers | math max })
  let next = $highest + 1
  let feature_num = ($next | into string | fill -a r -w 3 -c '0')

  # sanitize branch slug
  mut branch_name = ($feature_description | str downcase | str replace -a -r '[^a-z0-9]+' '-' | str trim -c '-')
  # take first 3 words
  let words = ($branch_name | split row '-' | where { |it| $it != '' } | take 3 | str join '-')
  $branch_name = $"($feature_num)-($words)"

  # create branch
  git checkout -b $branch_name | ignore

  let feature_dir = $"($specs_dir)/($branch_name)"
  mkdir $feature_dir

  let template = $"($repo_root)/templates/spec-template.md"
  let spec_file = $"($feature_dir)/spec.md"
  if ($template | path exists) { cp $template $spec_file } else { touch $spec_file }

  if $json_mode {
    { BRANCH_NAME: $branch_name SPEC_FILE: $spec_file FEATURE_NUM: $feature_num } | to json -r
  } else {
    print $"BRANCH_NAME: ($branch_name)"; print $"SPEC_FILE: ($spec_file)"; print $"FEATURE_NUM: ($feature_num)"
  }
}

# Run if executed directly (simple heuristic)
if (scope modules | where name == (pwd) | length) == 0 { main $env.CMDLINE_ARGS? } # fallback; typical usage: nu create-new-feature.nu ...
