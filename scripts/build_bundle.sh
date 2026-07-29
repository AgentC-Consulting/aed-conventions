#!/usr/bin/env bash
# Build the single-file distribution bundle: the whole AED canon, in reading
# order, in one markdown file. Regenerate after editing any chapter.
#
#   ./scripts/build_bundle.sh 1.1.0-rc.1
#
# The bundle exists so a reader — or an agent with one HTTP call and no git —
# can fetch the entire canon at once instead of walking eleven files.
set -euo pipefail

version_being_built="${1:?usage: build_bundle.sh <version, e.g. 1.1.0-rc.1>}"
repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

output_file="dist/aed-v${version_being_built}.md"
mkdir -p dist

chapters_in_reading_order=(
  01_why_models_need_this.md
  02_naming_conventions.md
  03_process_managers.md
  04_feature_stories.md
  CONVENTIONS.md
  06_control_flow.md
  07_how_the_workflow_runs.md
  quick_reference.md
)

{
  cat <<HEADER
# AED Conventions — the complete canon (v${version_being_built})

> **This file is generated.** It is every chapter of
> [AED Conventions](https://github.com/AgentC-Consulting/aed-conventions)
> concatenated in reading order, so the whole thing can be fetched with one
> request or pasted into one context window. The repository is canonical; if
> this file and the repository disagree, the repository wins.
>
> Fetch the newest copy:
> \`https://raw.githubusercontent.com/AgentC-Consulting/aed-conventions/v${version_being_built}/dist/aed-v${version_being_built}.md\`
>
> Chapters 01–04, 07 and the quick reference are the author's original notes,
> published verbatim — including his own work-in-progress markers. Chapter 05
> (\`CONVENTIONS.md\`) and chapter 06 are later work.
>
> Licensed CC BY 4.0 (prose) and MIT (code examples) — AgentC Consulting,
> https://agentc.consulting

## Contents

HEADER

  for chapter_file in "${chapters_in_reading_order[@]}"; do
    chapter_title="$(head -1 "$chapter_file" | sed 's/^#* *//')"
    printf -- '- %s — `%s`\n' "$chapter_title" "$chapter_file"
  done

  for chapter_file in "${chapters_in_reading_order[@]}"; do
    printf '\n\n---\n\n<!-- source: %s -->\n\n' "$chapter_file"
    # Demote every heading one level so the bundle keeps a single H1 at the top
    # and each chapter title becomes an H2 the reader can navigate by.
    #
    # This must skip fenced code blocks: the Crystal examples are full of
    # comment lines that start with "#", and a blind substitution turns
    # "# ✅ AED — reads like a statement" into a document heading.
    awk '
      /^[ \t]*(```|~~~)/ { currently_inside_a_code_fence = !currently_inside_a_code_fence; print; next }
      !currently_inside_a_code_fence && /^#{1,5} / { print "#" $0; next }
      { print }
    ' "$chapter_file"
  done
} > "$output_file.tmp"

# The bundle is a standalone file — someone may curl it with no repository
# around it at all. Every relative link inside it would dangle, so rewrite them
# to absolute URLs pinned to this tag. Skipped inside code fences, where a
# "](...)" sequence belongs to the example, not to us.
canonical_blob_base="https://github.com/AgentC-Consulting/aed-conventions/blob/v${version_being_built}"
perl -pe '
  BEGIN { $inside_a_code_fence = 0 }
  if (/^\s*(```|~~~)/) { $inside_a_code_fence = !$inside_a_code_fence }
  unless ($inside_a_code_fence) {
    s{\]\((?!https?://|mailto:|\#)([^)]+)\)}{]('"$canonical_blob_base"'/$1)}g
  }
' "$output_file.tmp" > "$output_file"
rm -f "$output_file.tmp"

printf 'built %s (%s lines, %s)\n' \
  "$output_file" "$(wc -l < "$output_file" | tr -d ' ')" \
  "$(du -h "$output_file" | cut -f1 | tr -d ' ')"
