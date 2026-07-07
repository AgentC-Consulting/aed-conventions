#!/usr/bin/env bash
# Push the canonical history (with tags) to the record-keeping mirrors.
# Inert until the remotes exist — set them up once, after the owner's go-ahead:
#   git remote add gitlab   git@gitlab.com:agentc-consulting/aed-conventions.git
#   git remote add codeberg git@codeberg.org:AgentC-Consulting/aed-conventions.git
set -euo pipefail

for mirror in gitlab codeberg; do
  if git remote get-url "$mirror" >/dev/null 2>&1; then
    echo "Pushing main + tags to $mirror..."
    git push --follow-tags "$mirror" main
  else
    echo "Remote '$mirror' not configured — skipping (see comments in this script)."
  fi
done
