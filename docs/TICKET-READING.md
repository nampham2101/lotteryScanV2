# Reading a ticket

The rule item 6 follows to find the province, ticket number and draw date on a photo. It was checked against four real tickets (see "The four tickets"). The photos are not kept in the project.

## The rule

One rule covers every province. There are no boxes per province.

- **Measure from the ticket's edges.** Not from the photo's edges and not from the dashed frame on screen. Tickets sit slightly crooked, so measure at the place you are looking at.
- **Province:** read it from the title strip on top, the line that starts with "XỔ SỐ KIẾN THIẾT".
- **Date:** the first date found searching the bottom band from left to right.
- **Ticket number:** the first six digits in a row, searching the bottom band from right to left.
- **Ignore the smaller copies** of the number and the date. They are printed elsewhere on the ticket and in the bottom band (for example Long An repeats "THỨ BẢY 24-10-2026" under its big number).
- **Ignore the sideways copies on the left and right edges.** Some tickets print the number sideways down an edge, in large type, partly cut off on the right. They are not smaller, and they run into the bottom band, so the band does not keep them out. On the right edge the search from right to left reaches them first, so they must be skipped on purpose.
- **Dates can be printed with or without spaces**, as in `20-10-2026` and `30 - 10 - 2026`. Read both as the same thing.

## Area sizes

Both are shares of the ticket's height, measured from the ticket's own top and bottom edges.

| Area | Share of ticket height | Holds |
|---|---|---|
| Top area | 20% from the top edge | Title strip (province) |
| Bottom band | 35% up from the bottom edge | Big ticket number and date |

How they were checked. Every title ends between 15% and 18% from the top, so 20% holds it, with about 2 points to spare on Vĩnh Long, the tightest. The big number's tallest digit starts between 26% and 32% from the bottom, so the band has to be at least 32% (Bạc Liêu's "8" on IMG_5902). The nearest smaller copy of the number or date above the big number is about 38% from the bottom (Vĩnh Long's small date), so the band has to stay under 38%. 35% sits inside that range on all four photos, about 3 points from each end.

The band does not keep out every other copy of the number or date:

- **Smaller copies inside the band** are ignored by the rule, such as Long An's "THỨ BẢY 24-10-2026" under its big number.
- **Sideways copies on the edges** also fall inside the band and are ignored. Long An prints its number sideways down the left edge: its "0" sits about 25% to 32% from the bottom, inside the band, and the next digit starts about 36% up, just outside it. All four tickets have large sideways print on the right edge, partly cut off. On Long An and Vĩnh Long it is clearly a large copy of the number.
- **Other digits in the band:** Vĩnh Long's band also holds "2.000.000.000đ" and "997". The dots break the first and neither is six digits in a row.

### Measurements per photo

Pixels are in the upright photo as shown. IMG_5902, IMG_5903 and IMG_5905 are 1600 wide and 2133 tall (stored as 2133 by 1600 and turned upright). IMG_5904 is 1200 wide and 1600 tall. All were read by eye, so each share is good to about 1 to 2 points. "Height" is the ticket's top edge to its bottom edge, measured at the digits (or the title) it is used for, not at the ticket's ends, because the tickets sit crooked and bent. Each share is the distance from the ticket's edge divided by that height.

| Photo | Province | Ticket height | Title ends | Top area needed | Big digits start | Bottom band needed | Nearest small copy above |
|---|---|---|---|---|---|---|---|
| IMG_5902 | Bạc Liêu | about 633 (top 942, bottom 1575) | y 1035 | 15% | y 1370 | 32% | y 1175, 63% from bottom |
| IMG_5903 | Long An | about 605 (top 938, bottom 1543) | y 1030 | 15% | y 1388 | 26% | none above the big number (the sideways copy on the left edge runs into the band) |
| IMG_5904 | Vĩnh Long | about 465 (top 643, bottom 1108) | y 725 | 18% | y 982 | 27% | y 932, 38% from bottom |
| IMG_5905 | Bạc Liêu | about 618 (top 765, bottom 1383) | y 865 | 16% | y 1202 | 29% | y 1020, 59% from bottom |

## The four tickets

The correct answers for item 6 to check against.

| Photo | Province | Ticket number | Date |
|---|---|---|---|
| IMG_5902 | Bạc Liêu | 871723 | 20-10-2026 |
| IMG_5903 | Long An | 051669 | 24-10-2026 |
| IMG_5904 | Vĩnh Long | 011221 | 30-10-2026 (printed `30 - 10 - 2026`) |
| IMG_5905 | Bạc Liêu | 747421 | 03-11-2026 |

Three provinces: Bạc Liêu (two tickets), Long An, Vĩnh Long.

## Known risk, not tested yet

Bạc Liêu prints its big number with doubled digits: each digit has a faint outline copy and small word labels (such as "Bảy", "Bốn") overlapping it. The rule above has not been tried on this. Item 6 should check that the six digits still come out as one run of six, and that the doubling doesn't add or drop a digit.
