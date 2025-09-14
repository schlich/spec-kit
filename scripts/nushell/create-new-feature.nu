#!/usr/bin/env nu
# Create a new feature (Nushell port of bash/create-new-feature.sh)

use ./common.nu *

# Help text function (kept separate for clarity)
def help [] { print 'Usage: create-new-feature.nu [--json] <feature description>'; }

# NOTE:
# Rely on Nushell's native script invocation: `nu scripts/nushell/create-new-feature.nu <desc>`
# Defining parameters directly avoids the need to manually inspect $env.CMDLINE_ARGS (which was
# previously causing lost arguments and an always-empty description for some invocation patterns).

export def main [
  --json               # output machine-readable JSON
  ...feature_description: string  # the rest of the words form the feature description
] {
  let feature_description = ($feature_description | str join ' ' | str trim)
  if ($feature_description | is-empty) { help; error make { msg: 'Feature description required' } }

  let repo_root = (get_repo_root)
  let specs_dir = $"($repo_root)/specs"
  mkdir $specs_dir

  # determine highest existing NNN prefix
  let existing_numbers = (ls $specs_dir | where type == 'dir' | get name | path basename | parse -r '^(?P<num>[0-9]+)-' | default {num: []} | get num | each { |n| $n | into int } )
  let highest = (if ($existing_numbers | is-empty) {0} else { $existing_numbers | math max })
  let next = $highest + 1
  let feature_num = ($next | into string | fill -a r -w 3 -c '0')

  # sanitize branch slug: lowercase, collapse non-alphanumerics to '-', trim edges
  let sanitized = ($feature_description | str downcase | str replace -a -r '[^a-z0-9]+' '-' | str trim -c '-')
  # take first 3 hyphen-separated words for brevity
  let words = ($sanitized | split row '-' | where { |it| $it != '' } | take 3 | str join '-')
  let branch_name = $"($feature_num)-($words)"

  # create git branch (ignore if already exists)
  if (git branch --list $branch_name | is-empty) {
    git checkout -b $branch_name | ignore
  } else {
    git checkout $branch_name | ignore
  }

  let feature_dir = $"($specs_dir)/($branch_name)"
  mkdir $feature_dir

  let template = $"($repo_root)/templates/spec-template.md"
  let spec_file = $"($feature_dir)/spec.md"
  if ($template | path exists) { cp $template $spec_file } else { touch $spec_file }

  if $json {
    { BRANCH_NAME: $branch_name SPEC_FILE: $spec_file FEATURE_NUM: $feature_num } | to json -r
  } else {
    print $"BRANCH_NAME: ($branch_name)"; print $"SPEC_FILE: ($spec_file)"; print $"FEATURE_NUM: ($feature_num)"
  }
}

