# Conventions

The rules for code and files in this project. Each rule is short and has an example.

## Folder structure

- **The app lives in `app/`.** Everything Flutter goes inside it.
  - Example: `app/lib/main.dart`, `app/test/`, `app/pubspec.yaml`.
- **Docs live in `docs/`.** Design sketches go in `docs/design/`.
  - Example: `docs/CONVENTIONS.md`, `docs/design/screens.png`.
- **Setup files stay at the top level.** Only the files that set up or describe the whole repo.
  - Example: `README.md`, `setup.sh`, `.fvmrc`, `.gitignore`.
- **Inside `app/lib/`, code used in more than one place lives in one shared place.** Don't paste the same helper twice.
  - Example: a date-parsing helper used by two screens goes in `app/lib/shared/`, not in each screen's folder.

## Naming

Dart and Flutter code.

- **Files and folders:** `snake_case`.
  - Example: `ticket_reader.dart`, `result_screen.dart`.
- **Classes, enums, typedefs:** `UpperCamelCase`.
  - Example: `TicketReader`, `DrawResult`.
- **Variables, functions, parameters:** `lowerCamelCase`.
  - Example: `ticketNumber`, `readTicket()`.
- **Constants:** `lowerCamelCase`, not `SCREAMING_CAPS`.
  - Example: `const defaultProvince = 'Bến Tre';`
- **Private names start with `_`.**
  - Example: `_parseDate()`.
- **Screens end in `Screen`, widgets in a noun that says what they show.**
  - Example: `HomeScreen`, `PrizeBanner`.
- **Booleans read as a yes/no question.**
  - Example: `isDrawn`, `hasWon`.

## Code style

- **Format with `dart format`.** No hand-formatting, no arguments about layout.
  - Example: `fvm dart format app/`
- **Fix every `flutter analyze` warning** before committing. Don't silence one without a comment saying why.
  - Example: `// ignore: avoid_print, the scan script prints on purpose` keeps its reason on the same line.
- **Single quotes for strings.**
  - Example: `'Good luck next time'`, not `"Good luck next time"`.
- **Use `const` wherever Dart allows it.**
  - Example: `const Text('Won')`.
- **Small files, small functions.** If a function needs a comment to explain what a block does, move that block into a function with a clear name.
  - Example: `_parseDrawDate(text)` instead of a 30-line block inside `readTicket()`.
- **Comments explain why, not what.**
  - Example: `// ML Kit drops accents on some fonts, so compare without them.`
- **Text shown to the user is in Vietnamese.**
  - Example: `'Chúc bạn may mắn lần sau'`.

## Commit format

Conventional Commits: `type(scope): subject`.

- **Subject:** imperative, lowercase, no full stop at the end.
- **Scope:** optional, a short word for the area changed.
- **Ticket:** mention the ticket number at the end of the subject when the commit belongs to one.
- **Allowed types:**

| Type | Use for |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `test` | Adding or changing tests |
| `refactor` | Code change that doesn't change behavior |
| `perf` | Code change that makes it faster |
| `ci` | Build and automation files |
| `chore` | Anything else that isn't app behavior (ignore files, tool versions) |

- Examples from this repo's history:
  - `docs: add screen sketches, design rule and ticket backlog`
  - `feat(setup): pin flutter 3.47.9 with fvm and add setup script`
  - `fix(agents): pin implementer to full sonnet model id`
  - `chore: ignore macos .ds_store files`
- Example with a ticket: `docs: add project conventions (#1)`

## Scope policy

**A pull request does one thing.** Nothing silently dropped, nothing silently smuggled in: every finding becomes a visible line in the pull request or a readable issue.

When you find something outside the task you were given:

| What you find | What you do |
|---|---|
| Something that blocks the task | Stop immediately and report it. Don't fix it. |
| Something trivial in a file you're already changing (typo, broken link, outdated comment) | Fix it and mention it in the pull request. |
| Anything else | Don't touch it. File an issue. |
| A security or data-loss risk | Stop immediately and report it. |

- Example: while adding the result screen you see a typo in a comment in the same file. Fix it and list it in the pull request.
- Example: while adding the result screen you see the camera screen has a layout bug. Don't fix it. File an issue.
