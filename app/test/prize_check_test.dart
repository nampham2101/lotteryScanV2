import 'package:flutter_test/flutter_test.dart';
import 'package:lotteryscan/shared/prize_check.dart';

// Tests for ticket #27: work out the prizes a ticket number wins.
//
// `prizesWon(ticketNumber, winningNumbers)` takes the six-digit ticket number
// and one province's 18 winning numbers, in order from Đặc biệt down to Giải
// Tám: ĐB, Nhất, Nhì, Ba x2, Tư x7, Năm, Sáu x3, Bảy, Tám. It gives back every
// prize won, each with a `name` and an `amount` in đồng. Any kind of item with
// those two fields passes, and the order of the prizes isn't checked.

// Bạc Liêu, 10/11/2026. ĐB, Nhất, Bảy and Tám are the real numbers from the
// ticket. The ticket doesn't give the other 14, so these are made up so that
// none of the tickets checked below matches them.
const _bacLieu = [
  '267832', // Đặc biệt (real)
  '06065', // Nhất (real)
  '48213', // Nhì
  '57390', '90124', // Ba
  '13579', '24680', '35791', '46802', '57913', '68024', '79135', // Tư
  '3456', // Năm
  '4567', '5678', '6789', // Sáu
  '807', // Bảy (real)
  '82', // Tám (real)
];

// Hồ Chí Minh, 09/11/2026. ĐB and Tám are the real numbers from the ticket;
// the other 16 are made up so that ticket 921443 matches none of them.
const _hoChiMinh = [
  '921440', // Đặc biệt (real)
  '50817', // Nhất
  '62934', // Nhì
  '73051', '84162', // Ba
  '95273', '06384', '17495', '28506', '39617', '40728', '51839', // Tư
  '6295', // Năm
  '7306', '8417', '9528', // Sáu
  '139', // Bảy
  '43', // Tám (real)
];

// A made-up set of results. Each tier's numbers end differently from every
// other tier's, so each ticket in the last group matches only one tier.
const _madeUp = [
  '135792', // Đặc biệt
  '24680', // Nhất
  '31415', // Nhì
  '27182', '16180', // Ba
  '11223', '34455', '66778', '89900', '12121', '34343', '56565', // Tư
  '7788', // Năm
  '9911', '2233', '4466', // Sáu
  '505', // Bảy
  '37', // Tám
];

const _dacBiet = ('Giải Đặc biệt', 2000000000);
const _nhat = ('Giải Nhất', 30000000);
const _nhi = ('Giải Nhì', 15000000);
const _ba = ('Giải Ba', 10000000);
const _tu = ('Giải Tư', 3000000);
const _nam = ('Giải Năm', 1000000);
const _sau = ('Giải Sáu', 400000);
const _bay = ('Giải Bảy', 200000);
const _tam = ('Giải Tám', 100000);
const _mayMan = ('Giải may mắn', 50000000);
const _khuyenKhich = ('Giải khuyến khích', 6000000);

List<(String, int)> _won(String ticketNumber, List<String> results) => [
  for (final prize in prizesWon(ticketNumber, results))
    (prize.name, prize.amount),
];

void main() {
  test('Given Bạc Liêu 10/11, when ticket 267832 is checked, '
      'then the result is Giải Đặc biệt, 2.000.000.000đ, and nothing else '
      '(no may mắn, no khuyến khích)', () {
    expect(_won('267832', _bacLieu), [_dacBiet]);
  });

  test('Given Bạc Liêu 10/11, when ticket 206065 is checked, '
      'then the result is Giải Nhất, 30.000.000đ', () {
    expect(_won('206065', _bacLieu), [_nhat]);
  });

  test('Given Bạc Liêu 10/11, when ticket 167832 is checked '
      '(last 5 digits match ĐB), then the result is Giải may mắn, '
      '50.000.000đ, and not khuyến khích as well', () {
    expect(_won('167832', _bacLieu), [_mayMan]);
  });

  test('Given Bạc Liêu 10/11, when ticket 267833 is checked '
      '(one digit wrong), then the result is Giải khuyến khích, '
      '6.000.000đ', () {
    expect(_won('267833', _bacLieu), [_khuyenKhich]);
  });

  test('Given Hồ Chí Minh 09/11, when ticket 921443 is checked, '
      'then the result lists both Giải khuyến khích, 6.000.000đ, '
      'and Giải Tám, 100.000đ', () {
    expect(_won('921443', _hoChiMinh), unorderedEquals([_khuyenKhich, _tam]));
  });

  test('Given Bạc Liêu 10/11, when ticket 111111 is checked, '
      'then the result is no prize', () {
    expect(_won('111111', _bacLieu), isEmpty);
  });

  group('Given a made-up set of results, when a ticket matching each tier '
      'from Nhì down to Tám is checked, then each gives its correct prize '
      'and the amount from the table', () {
    test('Nhì: ticket 931415 matches the last 5 digits of 31415, '
        'Giải Nhì, 15.000.000đ', () {
      expect(_won('931415', _madeUp), [_nhi]);
    });

    test('Ba: ticket 516180 matches the last 5 digits of the second Ba '
        'number, 16180, Giải Ba, 10.000.000đ', () {
      expect(_won('516180', _madeUp), [_ba]);
    });

    test('Tư: ticket 756565 matches the last 5 digits of the seventh Tư '
        'number, 56565, Giải Tư, 3.000.000đ', () {
      expect(_won('756565', _madeUp), [_tu]);
    });

    test('Năm: ticket 407788 matches the last 4 digits of 7788, '
        'Giải Năm, 1.000.000đ', () {
      expect(_won('407788', _madeUp), [_nam]);
    });

    test('Sáu: ticket 624466 matches the last 4 digits of the third Sáu '
        'number, 4466, Giải Sáu, 400.000đ', () {
      expect(_won('624466', _madeUp), [_sau]);
    });

    test('Bảy: ticket 880505 matches the last 3 digits of 505, '
        'Giải Bảy, 200.000đ', () {
      expect(_won('880505', _madeUp), [_bay]);
    });

    test('Tám: ticket 990037 matches the last 2 digits of 37, '
        'Giải Tám, 100.000đ', () {
      expect(_won('990037', _madeUp), [_tam]);
    });
  });
}
