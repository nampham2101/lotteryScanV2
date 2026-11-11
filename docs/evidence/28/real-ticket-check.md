# Manual step 1: a real ticket against the live feed, on the Pixel 7

- **Device:** Pixel 7, release build of branch `ticket-28-fetch-results` (installed with `fvm flutter build apk --release` and `adb install -r`), on 11 November 2026.
- **Permission:** `adb shell dumpsys package com.nampham.lotteryscan` lists `android.permission.INTERNET` among the requested permissions (Android also lists `android.permission.ACCESS_LOCAL_NETWORK`).
- **Ticket:** Nam's paper Bình Phước ticket 628918, dated 07-11-2026. Nam lined it up in the dashed frame; `/work` tapped the shutter over adb, waited 16 seconds and took `real-ticket-pixel7.png`.
- **Live feed at the time:** draw days 07/11 to 11/11.

## What the screen showed

```
Số vé: 628918
Tỉnh: Bình Phước
Ngày: 07-11-2026
Chưa trúng lần này
```

All three fields match the paper ticket.

## Checked by hand

Bình Phước 07/11 in the live feed:

```
ĐB: 508805
1: 64229
2: 75545
3: 06275 - 35520
4: 37465 - 01695 - 41507 - 73219 - 97075 - 86244 - 00262
5: 0819
6: 0656 - 8893 - 7360
7: 4528: 15        (Bảy 452, Tám 15)
```

With the table in `docs/PRIZES.md`, ticket 628918 matches no prize: no prize's number equals the ticket's last digits, the last five digits 28918 aren't ĐB's 08805 (no may mắn), and 628918 differs from 508805 in more than one digit (no khuyến khích). So "Chưa trúng lần này" is the right answer.
