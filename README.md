# Lottery Scan

A small app that reads a photo of a Vietnamese lottery ticket and tells the person whether they won.

## What the app does

1. The person takes a photo of one lottery ticket with their phone camera.
2. The app reads three things from the ticket: the **ticket number**, the **draw date** and the **province**.
3. The app shows the result:
   - **Won:** the ticket number and the prize, with a small celebration.
   - **Lost:** a "Good luck next time" message with a small animation.
   - **Draw not happened yet:** "No results yet, come back later."
   - **Photo can't be read:** a general "Sorry, can you try again?" message.

That's all it does.

## Who it's for

Anyone who buys a lottery ticket and has a smartphone with a camera.

## First version (MVP)

- **Tickets:** Xổ số kiến thiết paper tickets, miền Nam only.
- **Phones:** any phone with a camera, whatever the operating system.
- **Language:** Vietnamese.
- **One ticket at a time:** one photo holds one ticket.

### First gate: reading the ticket

Before anything else, the MVP has to prove it can read a ticket from a photo.

- **Test:** three ticket photos from three different provinces.
- **Pass:** all three things (ticket number, draw date, province) are read correctly on all three tickets.
- **If it passes:** we continue building.
- **If it fails:** we stop and look at other options (native app, another library, or something else).

## Decisions

- **A downloaded app, not a web app.** Leaves room to grow and add features that need the phone (full camera control, the phone's built-in text reader, notifications).
- **Built with Flutter.** One app for Android and iOS. Chosen because it has fewer moving parts, and its checkup command (`flutter doctor`) says plainly what's missing or broken.
  - *Revisit if:* we plan to hire JavaScript developers, or want a website that shares code with the app.
- **The ticket is read on the phone**, with Google's free ML Kit text reader (Flutter add-on `google_mlkit_text_recognition`), not by an AI service. Faster, works offline, and has no fees.
- **No cost each time someone uses the app.** Scanning a ticket and checking the result must be free. The app is free for users. App store fees are fine.

## Leaning (not final)

- **Android first, tested on an emulator.** Most users are expected to have Android phones. There's no Android phone for testing yet.

## Open questions (parked for later)

- **Where the winning results come from:** needs a source that is free to use.
- **Vietnamese accents:** not yet checked whether the ML Kit reader reads province names with accents (e.g. "Bến Tre") correctly.

## Repository

No code yet. This README is the only file so far.
