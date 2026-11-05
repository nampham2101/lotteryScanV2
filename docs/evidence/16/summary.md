# What ML Kit read on the ticket photos (ticket #16)

ML Kit text recognition (Latin script, on the device) was run on the five pictures in [`docs/photos/`](../../photos/) on the `Pixel_10` emulator (Android 17, API 37, arm64; the Pixel 7 phone was not used). The device is in every JSON file and in [`run-app.log`](run-app.log). Commands: [`commands.md`](commands.md). Full output, with the text, bounding box and corner points of every block, line, word (element) and letter (symbol): `IMG_5902.json`, `IMG_5903.json`, `IMG_5904.json`, `IMG_5905.json`, `dalat.json`.

This is only what was read. There is no reading rule and no go / no-go call here.

## How "appears anywhere" was counted

- **Yes (one word)**: the full value is inside one ML Kit word (element). A prefix such as `C` or `CN-` stuck to it still counts, and is noted.
- **Split**: the digits are all there, but spread over several words, or with stray characters, or a missing dash. These are not a plain yes.
- **No**: not there in either form.
- Searched on the JSON by script (the words, the lines, the lines with spaces removed, the digits of each block and of the whole text), then each hit was looked at in the JSON for its position and angle. Where a hit comes from, it says if it is the **big** number (the large digits along the bottom), a **small** copy, or a **sideways** copy on an edge. The accent check is exact letters, ignoring upper or lower case.
- The picture size in the JSON is what Flutter decodes from the file, which is the picture ML Kit was handed (the files carry no rotation note). ML Kit does not report a size itself. Every box in the JSON sits inside that size.

## Table

Correct answers are in [`docs/TICKET-READING.md`](../../TICKET-READING.md). Đà Lạt: number 152712, date CN-24-11-2019, province Đà Lạt.

| Picture | Ticket number | Date | Province | Province accents came through? |
|---|---|---|---|---|
| IMG_5902 (Bạc Liêu, 871723, 20-10-2026) | **Yes (one word)**, twice: `871723` and `C871723`, both small copies in the top strip. The big number along the bottom was not read at all. | **Yes (one word)**: `20-10-2026`, bottom left. | **Yes, without the dot under A**: title line reads `BAC LIÊUM0LOOOn` (the words `BAC` and `LIÊUM0LOOOn`; the "10.000đ" is glued on to LIÊU). The sideways logo text reads `BAC LIỆU`. | **Partly.** Ê came through in the title (`LIÊU`). Ạ was lost every time (`BAC`). The sideways copy has the wrong accent (`LIỆU`, with ệ). |
| IMG_5903 (Long An, 051669, 24-10-2026) | **Split only**: `D051` and `669` are two words on one line, the sideways copy on the left edge (angle about -86 degrees), with a stray `D`. No word holds the six digits. The big number along the bottom was not read. | **Yes (one word)**: `24-10-2026`, bottom, under "MỞ NGÀY THỨ BẢY". | **Yes**: `Long An` twice, but only in small print (`KQXS Long An soąn:`, `In tại CTy CP in Long An`). The title strip "XỔ SỐ KIẾN THIẾT LONG AN" was not read; only `XỔ số KIẾN THIẾT` from the diamond logo under the clock was. | Not applicable: the name has no accents. |
| IMG_5904 (Vĩnh Long, 011221, 30-10-2026) | **Yes (one word)**: `011221`, the small copy in the box on the left. The right-hand small copy is **split** (`0112`, `2`, `1`). The big number along the bottom was not read. | **Yes (one word)**: `30-10-2026`, the small copy on the right. The date printed `30 - 10 - 2026` is **split** into `O30-`, `10-`, `2026`, with a stray `O`. | **Yes, without the tilde on I**: `VINH LONG` in the title line (`XŐ SỐ KIỄN THIẾT VINH LONG HnOOna`), and `VIinh Long` in the small print. | **No.** Ĩ became `I` (and `Ii` in the small print). |
| IMG_5905 (Bạc Liêu, 747421, 03-11-2026) | **No.** Nothing holds 747421. Closest: `C747431` (one digit wrong, 2 read as 3), a small copy. The big number was not read. | **Split / damaged**: `0311-2026` is one word with the first dash lost (all the digits, but not `03-11-2026`). | **No.** Closest: `THIETBACHIÊU` inside `631XOSỐKẾN THIETBACHIÊU 10LO0O00` (spaces lost, L read as H, dot under A lost). | **Partly, but it is not a read of the name.** Ê is there in `HIÊU`; Ạ is lost. |
| dalat (Đà Lạt, 152712, CN-24-11-2019) | **Yes (one word)**: `H152712` (a small copy on the left, with the `H` stuck to it). The small copy on the right is **split and damaged** (`Hl`, `52`, `7`, `12`: the 1s are lost or misread). The big number was not read. | **Yes (one word)**, three times: `CN-24-11-2019` (sideways on the left edge, bottom left, top right), with the `CN-` stuck on. | **Yes, without accents**: `DA LAT` (the logo) and `Dà Lạt` (small print, in `NHận KOXS Dà Lạt som nhất:`). Another small line reads `Da Lai`. | **Partly.** `à` and `ạ` came through once, in the small print. Đ was lost every time (`D`, `DA`). In the logo all three accents were lost (`DA LAT`). |

In none of the five did ML Kit read the big ticket number along the bottom as digits. The only big-print hit is Long An's sideways left-edge copy (split, with a stray `D`).

## Misreads (written down, not fixed)

Compared by eye against the pictures, in `docs/photos/`. Printed, then read.

**Noise from the background (IMG_5902 to IMG_5905).** The keyboard above the ticket was read as stray one-letter or short words: `C`, `V`, `B`, `H`, `N`, `M`, `K`, `L`, `alt`, `fn`, `Control` (and `olt`, `fr` on IMG_5905), each as its own block.

**IMG_5902 (Bạc Liêu)**
- `XỔ SỐ KIẾN THIẾT BẠC LIÊU` and `10.000đ` -> `871723 XỔ SỐ KIẾN THIẾT, BAC LIÊUM0LOOOn`: the small number from the top left sits in the same line, a comma was added, Ạ lost, and `10.000đ` was glued on as `M0LOOOn`.
- Sideways logo text `CÔNG TY XỔ SỐ KIẾN THIẾT BẠC LIÊU` -> `AG XE SÜ KIẾN THIẾT BAC LIỆU`.
- `LOẠI T10-K3` -> `LOẠI TỈ0-K3`.
- `MỞ NGÀY THỨ BA` -> `MỞ NGÀY, THỨ BA` (comma added).
- `Chúc mừng Ngày Phụ nữ Việt Nam 2010` -> `Chức mủng2010)`; the rest was not read.
- `2 TỶ ĐỒNG` -> `ZAN`, `DONGD`, `Fal` (as separate pieces).
- The big `871723` and the small words above it (`Tám Bảy Một ...`) were not read, except one `Bay`.

**IMG_5903 (Long An)**
- Sideways left copy `R 051669` -> `D051 669` (stray `D`, a space inside the number; the `R` is a separate block).
- Title strip `XỔ SỐ KIẾN THIẾT LONG AN` and `10.000đ`: not read (only `XỔ số KIẾN THIẾT` from the diamond logo under the clock, with ố read as `số`).
- `KQXS Long An soạn:` -> `KQXS Long An soąn:`; `XSLA gửi 997` -> `-XSLA gii 997`; `XSLA 10K4` -> `Dc XSLA 10K4`.
- `KHÔNG` -> `KHONG`; `MỘT` -> `MỌT`.
- Small words `Không Năm Một Sáu Sáu Chín` -> `KhôngNămzMộtzeSáee SåiShín`.
- Small date under the big number `THỨ BẢY 24-10-2026` -> `Y 2024sHU3` and `a4-10`.
- The round stamp's `TNHH` (in `CÔNG TY TNHH MTV ...`) -> `TNHA`.
- The border pattern of the diamond under the clock (spirals, no text) -> `9999999999` (angle about -43 degrees); this is not ticket text. The clock's `12` and `1981` (and `T7K`) were read correctly.
- The big `051669` was not read.

**IMG_5904 (Vĩnh Long)**
- `XỔ SỐ KIẾN THIẾT VĨNH LONG 10000đ` -> `XŐ SỐ KIỄN THIẾT VINH LONG HnOOna` (Ổ as Ő, Ế as Ễ, Ĩ as I, `10000đ` as `HnOOna`).
- `IN TẠI CTY CỔ PHẦN IN TỔNG HỢP CẦN THƠ` (sideways, left) -> `IN TAI CTY CỔ PHẲN IN TỐNG HOP CẢN THƠ`.
- `Giải đặc biệt 6 chữ số` -> `Giai đãc biệt 6 chứ số`.
- `2.000.000.000đ` -> `2.000.0O00.000a`.
- `30 - 10 - 2026` -> `O30- 10- 2026`.
- `Soạn: XSVL gửi 997 nhận KQXS Vĩnh Long` -> `San: XSVL gúi 997 nhận KQXS VIinh Long`.
- Small words `Không Một Hai Hai Hai Một` -> `Kdag Mộ! Một Hai Hai Một`; the small right-hand number `011221` -> `0112 2 1`.
- The big `011221` was not read (a stray `3MỘT` appears near it).

**IMG_5905 (Bạc Liêu)**
- `XỔ SỐ KIẾN THIẾT BẠC LIÊU` and `10.000đ` -> `631XOSỐKẾN THIETBACHIÊU 10LO0O00` (spaces lost, `631` stuck on, THIẾT as THIET, `10.000đ` as `10LO0O00`).
- Sideways logo text `CÔNG TY XỔ SỐ KIẾN THIẾT BẠC LIÊU` -> `TY X6s KIE`, `cÔNG`.
- `LOẠI T11-K1` -> `LOẠI T114K1 C`; `T11-K1` -> `Ti1-K1`.
- `MỞ NGÀY THỨ BA` -> `MỚ NGÀY THỨ BẢ`.
- `03-11-2026` -> `0311-2026` (first dash lost).
- Small number `C 747421` -> `C747431` (2 read as 3).
- Small words `Bảy Bốn Bảy Bốn Hai Một` -> `Biy Bốn Biy Bốn Hai Một`; further word pieces `Bay`, `Bn,`, `Báy`, `lai`, `Mit` and `4Bem7Tay`, `4Pér`, which sit on the big number's row.
- The big `747421` was not read.

**dalat (Đà Lạt)**
- `GIẢI ĐẶC BIỆT 2 TỶ ĐỒNG 10.000đ` -> `GIẢI ĐẬC BIỆT 2 TỶ ĐÔNG 0.000d>` (Ặ as Ậ, Ồ as Ô, the `1` lost, đ as `d>`).
- `XỔ SỐ KIẾN THIẾT LÂM ĐỒNG` -> only `TIET`.
- Logo `ĐÀ LẠT` -> `DA LAT`.
- `Nhận KQXSLD soạn tin:` -> `Nhận KOXSLD s0n tin:`; `XSLD gửi 996` -> `XSLD gài 996`. Q is read as O throughout (`KOXS`).
- `Nhận KQXS Đà Lạt siêu tốc, soạn: XSDL gửi 6142` -> `Nhận KOXS Da Lai sieu to.` and `s0gn: XSDL gin 6142`.
- `Nhận KQXS nhanh nhất: XSDL gửi 997` -> `Nha n KOXS nhanh ahất:` and `XSOl gùi 997`.
- `Nhận KQXS Đà Lạt sớm nhất:` -> `NHận KOXS Dà Lạt som nhất:`; `gửi 8177 hoặc 8277` -> `gửi 8177 hoac 8277`.
- `ĐL11K4` -> `BL11K4`.
- Small right-hand `H 152 712` -> `Hl 52 7 12`.
- Small bottom row `Một Hai Một Bảy ...` partly read (`Một`, `Hal`, `Bảy`, `Một`, `Hai`); the big `152712` was not read.

Not listed: stray reads whose printed text could not be told by eye (for example the small pieces around the stamps).
