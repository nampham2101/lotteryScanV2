# Prizes

The rules the app follows (ticket #27) to work out what a ticket number wins. The source is the table printed on the back of a Vĩnh Long ticket (10.000đ, 6-digit tickets). The same table applies to all 21 miền Nam provinces.

## The table

| Prize | How many | Digits matched | Amount |
|---|---|---|---|
| Giải Đặc biệt | 1 | 6 | 2.000.000.000đ |
| Giải Nhất | 10 | last 5 | 30.000.000đ |
| Giải Nhì | 10 | last 5 | 15.000.000đ |
| Giải Ba | 20 | last 5 | 10.000.000đ |
| Giải Tư | 70 | last 5 | 3.000.000đ |
| Giải Năm | 100 | last 4 | 1.000.000đ |
| Giải Sáu | 300 | last 4 | 400.000đ |
| Giải Bảy | 1.000 | last 3 | 200.000đ |
| Giải Tám | 10.000 | last 2 | 100.000đ |
| Giải may mắn | 9 | the last 5 digits of Đặc biệt, in order | 50.000.000đ |
| Giải khuyến khích | 45 | wrong by only one digit, in any position, compared with Đặc biệt | 6.000.000đ |

The feed gives 18 numbers per province: Đặc biệt (6 digits), Nhất, Nhì, Ba x2, Tư x7 (5 digits), Năm, Sáu x3 (4 digits), Bảy (3 digits), Tám (2 digits).

## May mắn and khuyến khích

- **Giải may mắn:** the ticket's last 5 digits equal the last 5 digits of Đặc biệt, in order, and the ticket is not the Đặc biệt ticket itself.
- **Giải khuyến khích:** the ticket differs from Đặc biệt in exactly one digit, in any position.
- **They never go together.** A ticket that differs from Đặc biệt only in its first digit fits both rules, and gets may mắn only.
- **The Đặc biệt ticket itself** wins Giải Đặc biệt and not may mắn (or khuyến khích).

## More than one prize

A ticket gets every prize it won, except what the rules above exclude. Example: 921443 against Hồ Chí Minh 09/11/2026 (ĐB 921440, Tám 43) wins Giải khuyến khích and Giải Tám. If a ticket matches several numbers in the same prize, each match is listed.

The code is `app/lib/shared/prize_check.dart`.
