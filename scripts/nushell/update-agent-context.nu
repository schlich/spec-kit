#!/usr/bin/env nu
# Nushell port of bash/update-agent-context.sh
# Updates agent context files (CLAUDE.md, GEMINI.md, .github/copilot-instructions.md) based on current feature plan

export def main [agent_type?:string] {
  let repo_root = (git rev-parse --show-toplevel | str trim)
  let current_branch = (git rev-parse --abbrev-ref HEAD | str trim)
  let feature_dir = $"($repo_root)/specs/($current_branch)"
  let new_plan = $"($feature_dir)/plan.md"
  if not ($new_plan | path exists) { print $"ERROR: No plan.md found at ($new_plan)"; exit 1 }

  print $"=== Updating agent context files for feature ($current_branch) ==="

  let read_line = {|pattern| (open $new_plan | lines | find -r $pattern | first? | default '' | str replace -r '^\*\*[^:]+\*\*: ' '' ) }
  let new_lang = (do $read_line '^\*\*Language/Version\*\*:' | str trim | if ($in =~ 'NEEDS CLARIFICATION') { '' } else { $in })
  let new_framework = (do $read_line '^\*\*Primary Dependencies\*\*:' | str trim | if ($in =~ 'NEEDS CLARIFICATION') { '' } else { $in })
  let new_db = (do $read_line '^\*\*Storage\*\*:' | str trim | if ($in =~ 'NEEDS CLARIFICATION' or $in == 'N/A') { '' } else { $in })
  let new_project_type = (do $read_line '^\*\*Project Type\*\*:' | str trim)

  let claude_file = $"($repo_root)/CLAUDE.md"
  let gemini_file = $"($repo_root)/GEMINI.md"
  let copilot_file = $"($repo_root)/.github/copilot-instructions.md"

  def infer_commands [] {
    if ($new_lang =~ 'Python') { 'cd src && pytest && ruff check .' } 
    else if ($new_lang =~ 'Rust') { 'cargo test && cargo clippy' } 
    else if ($new_lang =~ 'JavaScript' or $new_lang =~ 'TypeScript') { 'npm test && npm run lint' } 
    else { $"# Add commands for ($new_lang)" }
  }

  def ensure_file [target:string agent_name:string] {
    if not ($target | path exists) {
      print $"Creating new ($agent_name) context file..."
      let template = $"($repo_root)/templates/agent-file-template.md"
      if not ($template | path exists) { print 'ERROR: Template not found'; return }
      let content = (open $template | str join) # open returns structured lines sometimes; flatten
      let tech_line = $"- ($new_lang) + ($new_framework) ($current_branch)"
      let structure = (if ($new_project_type =~ 'web') { "backend/\nfrontend/\ntests/" } else { "src/\ntests/" })
      let commands = (infer_commands)
      let updated = ($content 
        | str replace '[PROJECT NAME]' (basename $repo_root)
        | str replace '[DATE]' (date now | format date '%Y-%m-%d')
        | str replace '[EXTRACTED FROM ALL PLAN.MD FILES]' $tech_line
        | str replace '[ACTUAL STRUCTURE FROM PLANS]' $structure
        | str replace '[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES]' $commands
        | str replace '[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE]' $"($new_lang): Follow standard conventions"
        | str replace '[LAST 3 FEATURES AND WHAT THEY ADDED]' $"- ($current_branch): Added ($new_lang) + ($new_framework)" )
      $updated | save -f $target
      print $"✅ ($agent_name) context file created"
    } else {
      update_existing $target $agent_name
    }
  }

  def update_existing [target:string agent_name:string] {
    print $"Updating existing ($agent_name) context file..."
    mut content = (open $target | str join)
    # Active Technologies section append if missing
    if ($new_lang != '' and ($content | str contains $new_lang) == false) {
      $content = ($content | str replace -r '## Active Technologies\n' $"## Active Technologies\n- ($new_lang) + ($new_framework) ($current_branch)\n")
    }
    if ($new_db != '' and ($content | str contains $new_db) == false) {
      $content = ($content | str replace -r '## Active Technologies\n' $"## Active Technologies\n- ($new_db) ($current_branch)\n")
    }
    # Recent Changes - prepend
    if ($content | str contains '## Recent Changes') {
      # naive extraction: split on header and reconstruct
      let parts = ($content | split row '## Recent Changes')
      if ($parts | length) > 1 {
        let tail = ($parts | skip 1 | str join '## Recent Changes')
        let after_header = ($tail | split row '\n' | skip 1) # skip first newline after header
        let existing = ($after_header | take 5 | where {|l| ($l | str starts-with '-') } | take 2)
        let new_block = ([$"- ($current_branch): Added ($new_lang) + ($new_framework)" ] | append $existing | str join "\n")
        $content = ($content | str replace '## Recent Changes' $"## Recent Changes\n($new_block)")
      }
    }
    # Update last updated date
    $content = ($content | str replace -r 'Last updated: [0-9]{4}-[0-9]{2}-[0-9]{2}' $"Last updated: (date now | format date '%Y-%m-%d')")
    $content | save -f $target
    print $"✅ ($agent_name) context file updated successfully"
  }

  match $agent_type {
    'claude' => { ensure_file $claude_file 'Claude Code' }
    'gemini' => { ensure_file $gemini_file 'Gemini CLI' }
    'copilot' => { ensure_file $copilot_file 'GitHub Copilot' }
    '' => {
      # update existing or create Claude by default
      if ($claude_file | path exists) { ensure_file $claude_file 'Claude Code' }
      if ($gemini_file | path exists) { ensure_file $gemini_file 'Gemini CLI' }
      if ($copilot_file | path exists) { ensure_file $copilot_file 'GitHub Copilot' }
      if (not ($claude_file | path exists) and not ($gemini_file | path exists) and not ($copilot_file | path exists)) { ensure_file $claude_file 'Claude Code' }
    }
    _ => { print $"ERROR: Unknown agent type '($agent_type)'"; exit 1 }
  }

  print ''
  print 'Summary of changes:'
  if $new_lang != '' { print $"- Added language: ($new_lang)" }
  if $new_framework != '' { print $"- Added framework: ($new_framework)" }
  if $new_db != '' { print $"- Added database: ($new_db)" }
  print ''
  print 'Usage: update-agent-context.nu [claude|gemini|copilot]'
}

main
