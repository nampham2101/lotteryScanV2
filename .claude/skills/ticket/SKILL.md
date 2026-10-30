---
name: ticket
description: Draft a GitHub issue for this project in the fixed ticket format, show it to Nam, and post it only after Nam says yes.
disable-model-invocation: true
---

# /ticket

Nam describes a piece of work. Turn it into a GitHub issue.

## 1. Draft the ticket

Use exactly these five sections:

- **Title:** short, plain, starts with a verb (e.g. "Test reading the three ticket fields from photos").
- **Why:** why the work is needed, in 1–3 sentences.
- **What to do:** a short bullet list of the steps.
- **Done when:** bullet list of checks that show the work is finished. Each one must be something Nam can see or verify.
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
- Do not assign anyone. Nam assigns tickets, and assignment is the go signal.
- The repository is public, so the issue is visible to everyone.

Show Nam the link to the new issue.
