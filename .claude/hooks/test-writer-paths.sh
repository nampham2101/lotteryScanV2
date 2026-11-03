#!/usr/bin/env bash
# PreToolUse hook for the test-writer agent: blocks Write/Edit outside the test writer's allowed files.
# Reads the hook's JSON from stdin. Exit 2 blocks the write and shows the message to the agent.

file="$(jq -r '.tool_input.file_path // empty')"
root="${CLAUDE_PROJECT_DIR:-$PWD}"

# Make the path relative to the project, refusing anything that climbs out of it.
case "$file" in
  "$root"/*) rel="${file#"$root"/}" ;;
  /*) rel="" ;;
  *) rel="$file" ;;
esac
[[ "$rel" == *..* ]] && rel=""

if [[ "$rel" =~ ^app/test/.+ ||
      "$rel" =~ ^app/integration_test/.+ ||
      "$rel" =~ ^docs/tests/[0-9]+\.md$ ||
      "$rel" == "app/pubspec.yaml" ||
      "$rel" == "app/pubspec.lock" ]]; then
  exit 0
fi

echo "Blocked: the test writer may only write in app/test/, app/integration_test/, docs/tests/<number>.md, app/pubspec.yaml (test add-ons) and app/pubspec.lock. Tried: $file" >&2
exit 2
