---
name: work
description: Run one assigned GitHub ticket through the workflow - test writer, implementer, checks, reviewer, pull request and merge. Nam types /work <issue number>.
disable-model-invocation: true
---

# /work <issue number>

You are the manager. You run one ticket from start to merge by handing work to the agents, checking it, and routing problems. You don't write app code or tests yourself. Rules and reasons: `docs/WORKFLOW.md`.

## 1. Check the ticket

- Read it: `gh issue view <number>`. Stop and tell Nam if it's closed, not assigned (assignment is the go signal), or has no "Done when".
- Start from an up-to-date `main`.

## 2. Tests (only if the ticket says "Test cases: needed")

- Run the **test-writer** agent on the ticket.
- If it stops on an unclear criterion: show Nam the question and ask him to fix the ticket with /refine, then run /work again. Stop here.
- Check its branch exists and `docs/evidence/<number>/first-run.txt` shows the tests failing because the feature is missing.

## 3. Build

- Run the **implementer** agent on the ticket, on the same branch.
- If it stops (question, blocker, security risk), or says a test contradicts the ticket: show Nam and stop.

## 4. Check (at most 3 fix rounds)

- Run `fvm flutter analyze` and the widget tests in `app/`, and the integration tests on the `Pixel_10` emulator. Save the output in `docs/evidence/<number>/`.
- Confirm the implementer changed no test files since the test writer's last commit.
- Run each manual step in `docs/tests/<number>.md` on the emulator. Save a screenshot or result for each in `docs/evidence/<number>/`. Compare screens with `docs/design/screens.png`.
- If anything fails: send it back to the implementer with exactly what failed, and check again. That's one round.
- After 3 rounds without passing: stop, and show Nam what failed and what was tried.

## 5. Review

- Run the **reviewer** agent on the ticket. Give it only the ticket number, never the implementer's report. It proves each "Done when" item and ticks the boxes when everything looks good.
- If it stops: show Nam and stop.
- If it finds problems: send each one to who it names, then go back to step 4. That's one round, counted with step 4's.
  - Code problem: the **implementer**, with exactly what's wrong.
  - A test that proves nothing: the **test writer**. Tell it to fix only that test on the existing branch; the feature exists now, so the test doesn't need to fail first.
- If it says everything looks good: continue.

## 6. Record

- Add anything found along the way, including the reviewer's suggested issues, to `docs/BACKLOG.md` as "not refined" items.

## 7. Pull request and merge

- Push the branch and open a pull request: "Closes #<number>", what this does, what changed, proof of testing (links to `main`), what the reviewer found, found along the way.
- Update `docs/STATUS.md` and `docs/BACKLOG.md` with the ticket and pull request number, commit on the branch, push.
- When every check has passed: squash-merge, delete the branch on GitHub and locally, update `main`, and confirm the ticket is closed.

## 8. Report to Nam

A short summary: what was built, the pull request link, the test results, what the reviewer found, how many fix rounds were used, what was added to the backlog, and anything worth looking at in the running app.
