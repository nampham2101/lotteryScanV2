#!/usr/bin/env bash
# PreToolUse hook for the implementer agent: blocks any Bash command that runs `git push`.
# Reads the hook's JSON from stdin. Exit 2 blocks the command and shows the message to the agent.

command="$(jq -r '.tool_input.command // empty')"

if grep -qE '(^|[;&|(]|[[:space:]])git([[:space:]]+[^[:space:];&|]+)*[[:space:]]+push([[:space:]]|$|[;&|)])' <<<"$command"; then
  echo "Blocked: the implementer must never push. Commit on your branch and report back; pushing happens later in the workflow." >&2
  exit 2
fi

exit 0
