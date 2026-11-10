---
name: work
description: Run one GitHub ticket through the workflow - assign it to Nam, then test writer, implementer, reviewer, checks, pull request and merge. Nam types /work <issue number>, and that is the go signal.
disable-model-invocation: true
---

# /work <issue number>

You are the manager. You run one ticket from start to merge by handing work to the agents, checking it, and routing problems. You don't write app code or tests yourself. Rules and reasons: `docs/WORKFLOW.md`.

## 1. Check the ticket

- `/work 8` and `/work ticket 8` both mean issue 8.
- Read it: `gh issue view <number>`. Stop and tell Nam if it's closed or has no "Done when".
- Assign it to Nam: `gh issue edit <number> --add-assignee @me`. Nam running `/work` is the go signal, so don't stop if it wasn't assigned before.
- Start from an up-to-date `main`.

## 2. Tests (only if the ticket says "Test cases: needed")

- Run the **test-writer** agent on the ticket.
- If it stops on an unclear criterion: show Nam the question and ask Nam to fix the ticket with /refine, then run /work again. Stop here.
- Check its branch exists and `docs/evidence/<number>/first-run.txt` shows the new tests and any older tests it updated failing because the feature or change is missing.

## 3. Build

- Run the **implementer** agent on the ticket, on the same branch.
- If it stops (question, blocker, security risk), or says a test contradicts the ticket: show Nam and stop.

Steps 4 and 5 share at most 3 fix rounds. After 3 rounds without passing: stop, and show Nam what failed and what was tried.

## 4. Review

- Run the **reviewer** agent on the ticket. Give it only the ticket number, never the implementer's report. It reviews all the ticket's changes every time, not just the latest fix, and reports every problem at once.
- If it stops: show Nam and stop.
- If it finds problems: send them all back in one go, then run the reviewer again. That's one round.
  - Code problems: the **implementer** fixes them all, with exactly what's wrong.
  - Tests that prove nothing: the **test writer**, in the same round. Tell it to fix only those tests on the existing branch; the feature exists now, so they don't need to fail first.
- If it says everything looks good: continue.

## 5. Check

- Follow the "Where these run" line in `docs/tests/<number>.md`: the test writer chose the device for each test. Start `Pixel_10` if it isn't running.
- If tests need a real phone, check `adb devices` lists one as `device`, and ask Nam to unlock it if it's locked. If none is connected: stop and tell Nam. Don't use the emulator instead.
- Put a phone's serial in `ANDROID_SERIAL`, never in the repo, and name the device in every command (`-d`, `adb -s`), since both may be connected.
- Run `fvm flutter analyze` and all the widget tests in `app/`.
- Run this ticket's tests, each on its device: its new tests and the older tests the test writer updated, listed in `docs/tests/<number>.md`. Don't run any other older tests, even if the ticket touched their code. They wait for the regression run before a release.
- **After a fix round,** rerun only analyze, the widget tests and the tests the implementer named as related to its fix, plus any test the test writer fixed in that round. Earlier passing runs of the other tests still count as proof. There is no final run of all the ticket's tests before the merge.
- Save the output in `docs/evidence/<number>/`, and say which device each run used.
- Confirm the implementer changed no test files since the test writer's last commit.
- Run each manual step in `docs/tests/<number>.md` on its device. Save a screenshot or result for each in `docs/evidence/<number>/`. Compare screens with `docs/design/screens.png`.
- Prove each "Done when" item, including every Given / When / Then and the checklist. Find the test or manual step that covers it and the saved output or screenshot showing it passed. Read the saved output and look at the screenshots yourself; a claim that something passed isn't proof.
- If something fails or isn't proven and it needs a code fix: send it to the implementer with exactly what failed, then go back to step 4. That's one round.
- If it needs no code fix (a run problem, like the phone held still, or a proof that wasn't saved): run that check again. That's one round.
- When everything passes and is proven: tick the "Done when" boxes in the ticket with `gh issue edit <number> --body-file <file>`, changing nothing else in it.

## 6. Record

- Add anything found along the way, including the reviewer's suggested issues, to `docs/BACKLOG.md` as "not refined" items.

## 7. Pull request and merge

- Push the branch and open a pull request: "Closes #<number>", what this does, what changed, proof of testing (links to `main`), what the reviewer found, found along the way.
- Update `docs/STATUS.md` and `docs/BACKLOG.md` with the ticket and pull request number, commit on the branch, push.
- When every check has passed: squash-merge, delete the branch on GitHub and locally, update `main`, and confirm the ticket is closed.

## 8. Report to Nam

A short summary: what was built, the pull request link, the test results, what the reviewer found, how many fix rounds were used, what was added to the backlog, and anything worth looking at in the running app.
