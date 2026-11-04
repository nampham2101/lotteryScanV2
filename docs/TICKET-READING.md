# Reading a ticket

The rule item 6 follows to find the province, ticket number and draw date on a photo. It was checked against four real tickets (see "The four tickets"). The photos are not kept in the project.

## The rule

One rule covers every province. There are no boxes per province.

- **Measure from the ticket's edges.** Not from the photo's edges and not from the dashed frame on screen. Tickets sit slightly crooked, so measure at the place you are looking at.
- **Province:** read it from the title strip on top, the line that starts with "XỔ SỐ KIẾN THIẾT".
- **Date:** the first date found searching the bottom band from left to right.
- **Ticket number:** the first six digits in a row, searching the bottom band from right to left.
- **Ignore the smaller copies** of the number and the date. They are printed elsewhere on the ticket and in the bottom band (for example Long An repeats "THỨ BẢY 24-10-2026" under its big number).
- **Dates can be printed with or without spaces**, as in `20-10-2026` and `30 - 10 - 2026`. Read both as the same thing.

## Area sizes

Both are shares of the ticket's height, measured from the ticket's own top and bottom edges.

| Area | Share of ticket height | Holds |
|---|---|---|
| Top area | 20% from the top edge | Title strip (province) |
| Bottom band | 35% up from the bottom edge | Big ticket number and date |

How they were checked. Every title ends between 14% and 17% from the top, so 20% holds it with room to spare. The big number's tallest digit starts between 27% and 31% from the bottom, so the band has to be at least 31%. The nearest smaller copy of the number or date above the big number is at least 37% from the bottom (Vĩnh Long's small date), so the band has to stay under 37%. 35% sits inside that range on all four photos.

### Measurements per photo

Pixels are in the upright photo, resized to 1600 on the long side, read by eye, so each share is good to about 1 point. "Height" is the ticket's top edge to its bottom edge at the place measured.

| Photo | Province | Ticket height | Title ends | Top area needed | Big digits start | Bottom band needed | Nearest small copy above |
|---|---|---|---|---|---|---|---|
| IMG_5902 | Bạc Liêu | about 635 (top 945, bottom 1580) | y 1040 | 15% | y 1385 | 31% | y 1160, 66% from bottom |
| IMG_5903 | Long An | about 610 (top 948, bottom 1558) | y 1035 | 14% | y 1390 | 27% | none above the big number |
| IMG_5904 | Vĩnh Long | about 480 (top 645, bottom 1115) | y 725 | 17% | y 985 | 27% | y 935, 37% from bottom |
| IMG_5905 | Bạc Liêu | about 600 (top 778, bottom 1380) | y 865 | 15% | y 1205 | 30% | y 1000, 63% from bottom |

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
