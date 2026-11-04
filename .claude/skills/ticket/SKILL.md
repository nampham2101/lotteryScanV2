---
name: ticket
description: Draft GitHub issue(s) from the output of /refine, show them to Nam, and post each only after Nam says yes. /ticket update <issue number> changes an existing ticket the same way.
disable-model-invocation: true
---

# /ticket

Turn the task(s) that /refine produced into GitHub issues. To change an existing ticket, skip to "Updating an existing ticket" below.

## 0. Check for /refine output

If there's no /refine output for this work in the conversation, don't draft. Ask Nam to run /refine first.
If /refine produced several tasks, draft and post them one at a time.

## 1. Draft the ticket

Use exactly these sections, filled from /refine's summary:

- **Title:** short, plain, starts with a verb (e.g. "Test reading the three ticket fields from photos").
- **Why:** why the work is needed, in 1–3 sentences.
- **What to do:** a short bullet list of the steps.
- **Done when:** the acceptance criteria from /refine, unchanged.
- **Test cases:** the mark from /refine, unchanged: `needed — <reason>` or `not needed — <reason>`.
- **Not included:** bullet list of related things this ticket does not cover.

Keep it short and in plain words. No code unless Nam asks for it.

## 2. Pick labels

Choose one or more of the repository's existing labels. Don't create new ones:
`bug`, `enhancement`, `documentation`, `question`, `good first issue`, `help wanted`, `duplicate`, `invalid`, `wontfix`, `accessibility`.

## 3. Show it and wait

Show the full draft and the labels in chat. Ask Nam whether to post it.
Do not post until Nam says yes. If Nam asks for changes, update the draft and show it again.

## 4. Post it

After Nam says yes, post it with `gh issue create`, using the title, body and labels.
- Do not assign anyone. `/work` assigns the ticket when Nam runs it, and running it is the go signal.
- The repository is public, so the issue is visible to everyone.

Show Nam the link to the new issue.

## Updating an existing ticket

Nam types `/ticket update <issue number>` and says what should change.

1. Read it: `gh issue view <number>`. Stop and tell Nam if it's closed.
2. Change only what Nam asked for. Keep every other line exactly as it is, including ticked boxes. A new or changed "Done when" item goes through /refine first.
3. Show Nam each changed line, old and new. Do not change the ticket until Nam says yes.
4. After Nam says yes, apply it with `gh issue edit <number> --body-file <file>`. The repository is public, so the change is visible to everyone. Show Nam the link.
