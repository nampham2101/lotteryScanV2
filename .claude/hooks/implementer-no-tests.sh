#!/usr/bin/env bash
# PreToolUse hook for the implementer agent: blocks Write/Edit to the test writer's files.
# Reads the hook's JSON from stdin. Exit 2 blocks the write and shows the message to the agent.

file="$(jq -r '.tool_input.file_path // empty')"
root="${CLAUDE_PROJECT_DIR:-$PWD}"
rel="${file#"$root"/}"

if [[ "$rel" == *..* || "$rel" =~ ^app/test/ || "$rel" =~ ^app/integration_test/ || "$rel" =~ ^docs/tests/ ]]; then
  echo "Blocked: the implementer must never change the test writer's tests ($rel). If a test contradicts the ticket, stop and report it." >&2
  exit 2
fi

exit 0
