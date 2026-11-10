# Reading a ticket

The rule the app follows (ticket #24) to find the ticket number, province and draw date in the text ML Kit reads from a photo. The four real tickets below give the correct answers to check it against. The photos are kept in the project, in [`docs/photos/`](photos/): `IMG_5902.jpg`, `IMG_5903.jpg`, `IMG_5904.jpg` (the clean Vĩnh Long one) and `IMG_5905.jpg`, upright and full size (3024 by 4032, or 4284 by 5712 for IMG_5903 and IMG_5905), plus `dalat.jpg`, a 520 by 252 picture of a Đà Lạt ticket (number 152712, date CN-24-11-2019) that is not one of the four. What ML Kit read on all five is in [`docs/evidence/16/`](evidence/16/summary.md).

## The rule

One rule covers every province. It works on ML Kit's text alone: where a field sits on the ticket does not matter, so there are no areas, no boxes per province, and no need to find the ticket's edges.

1. **Spaces are removed within each line** of ML Kit's text. Line breaks stay, so text never joins across lines. `D051 669` becomes `D051669`, and `30- 10- 2026` becomes `30-10-2026`.
2. **Ticket number:** the first six digits in a row. Letters around them are ignored (`C871723` gives `871723`), and a longer run gives its first six (`9999999999` gives `999999`). Digits on different lines never join.
3. **Province:** the first of the 21 names below found in the text. In the text and in the names alike, accents and spaces are removed, case is ignored and Đ reads as D. A name counts even when it is glued to other text (`BẠC LIEUOL0T010b` gives Bạc Liêu). The province is shown as written in the list. "First" means the name that starts earliest in the text; the longer name wins if two start together.
4. **Date:** the first exact `DD-MM-YYYY`, with the dashes. A missing dash is no match (`0311-2026`). Letters before it are ignored (`CN-24-11-2019` gives `24-11-2019`).
5. **The first match wins** for each field. Smaller copies of the number or date elsewhere on the ticket are read only if they come first in the text.
6. **If any of the three is missing, or the read fails, or ML Kit finds no text, the app shows screen 4d** ("Không đọc được vé"). It never shows a partial result.

The code is `app/lib/shared/ticket_fields.dart`.

### The 21 provinces

Each name is shown as written here. Where the words matched differ, they are given.

| Shown | Matches |
|---|---|
| An Giang | An Giang |
| Bạc Liêu | Bac Lieu |
| Bến Tre | Ben Tre |
| Bình Dương | Binh Duong |
| Bình Phước | Binh Phuoc |
| Bình Thuận | Binh Thuan |
| Cà Mau | Ca Mau |
| Cần Thơ | Can Tho |
| Đà Lạt | `Da Lat` (not `Lam Dong`) |
| Đồng Nai | Dong Nai |
| Đồng Tháp | Dong Thap |
| Hậu Giang | Hau Giang |
| Kiên Giang | Kien Giang |
| Long An | Long An |
| Sóc Trăng | Soc Trang |
| Tây Ninh | Tay Ninh |
| Tiền Giang | Tien Giang |
| TP. Hồ Chí Minh | `Ho Chi Minh` |
| Trà Vinh | Tra Vinh |
| Vĩnh Long | Vinh Long |
| Vũng Tàu | Vung Tau |

## The four tickets

The correct answers for item 6 to check against.

| Photo | Province | Ticket number | Date |
|---|---|---|---|
| IMG_5902 | Bạc Liêu | 871723 | 20-10-2026 |
| IMG_5903 | Long An | 051669 | 24-10-2026 |
| IMG_5904 | Vĩnh Long | 011221 | 30-10-2026 (printed `30 - 10 - 2026`) |
| IMG_5905 | Bạc Liêu | 747421 | 03-11-2026 |

Three provinces: Bạc Liêu (two tickets), Long An, Vĩnh Long.

## Known risks

- **Wrong digits stay wrong.** The rule trusts the first six digits in a row. If ML Kit misreads a digit, the number is wrong and nothing notices (backlog item 90, retaking a wrong number).
- **A smaller or sideways copy can come first.** ML Kit's text has no position, so a smaller copy of the number printed earlier in the text, or the sideways number on a ticket's edge, wins if it has six digits in a row. The four tickets' sideways copies, Bạc Liêu's doubled digits and the like are checked in the gate report, which is its own ticket.
- **Digits with thousand dots** such as Vĩnh Long's `2.000.000.000đ` do not make six in a row.
