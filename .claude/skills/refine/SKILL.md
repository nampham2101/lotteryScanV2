---
name: refine
description: Refine a piece of work with Nam. Discuss it, split it into smaller tasks when needed, write acceptance criteria, and mark whether test cases are needed. Ends by telling Nam to type /ticket.
disable-model-invocation: true
---

# /refine

Nam describes a piece of work. Turn it into clear, well-defined task(s) with acceptance criteria.

## 1. Discuss

Ask Nam one question at a time until the work is clear: what it is, why it's needed, what's in and what's out.
Repeat each answer back in your own words and keep a running list of what's decided and what's open.

## 2. Split, only when needed

If the work holds more than one piece that can be finished and checked on its own, propose splitting it into smaller tasks.
If it's already one piece, keep it as one. Nam confirms the split.

## 3. Write acceptance criteria

For each task:
- **Behavior** (anything the user or the app does): write **Given / When / Then**.
  *Given* the starting situation, *when* something happens, *then* the result Nam can see or verify.
  Cover the normal case and the important failure cases.
- **Everything else** (setup, documents, files): a short checklist of things Nam can check.

Then mark each task **Test cases: needed** or **Test cases: not needed**, with a one-line reason.
Behavior tasks usually need them; checklist-only tasks usually don't.

**Proof of testing.** For every task marked *Test cases: needed*, add this item to its checklist:
- [ ] Proof of every test run, **passed or failed**, is committed in `docs/evidence/<issue number>/` and linked from the PR description. Saved test output is enough for anything an automated test proves. Use a screenshot for what only a manual step can show.

Show the criteria and the mark to Nam and change them until Nam confirms. Nam may override the mark.

## 4. Summarise and hand over

For each task, show a summary: a title idea, why it's needed, what to do, the acceptance criteria, the test-case mark, and what's not included.
End with: "Ready. Type /ticket to draft the ticket(s)." Do not start /ticket yourself.
