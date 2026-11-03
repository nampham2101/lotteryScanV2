# CLAUDE.md

What the project is: see [README.md](README.md).

## How we work in this project

These override the global defaults in `~/.claude/CLAUDE.md` where they differ.

- **One step at a time.** Do one small piece, then stop and wait for Nam.
- **Tell before acting.** Before creating, changing or writing down anything (files, notes, memory, commits), say what it is and wait for a yes.
- **No unrequested opinions.** Answer what is asked and do what is asked. No recommendations, judgments or extra work unless Nam asks for them.
- **During discussions:** ask one question at a time, repeat each answer back in your own words, and keep a running list of what's decided and what's open.

## Design

- Screens must follow the sketches in `docs/design/screens.png`. Don't invent new designs.
- If a screen or element isn't in the sketches, ask Nam before building it.

## Status document

- At the start of every session, read `docs/STATUS.md`.
- Whenever something is finished (a ticket, a harness setting, a decision), update `docs/STATUS.md` without asking, tell Nam what changed, and include it in the same commit as the finished work. This is the one exception to "Tell before acting".
