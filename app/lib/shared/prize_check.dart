/// One prize a ticket wins.
class Prize {
  const Prize(this.name, this.amount);

  /// The prize's name as printed on the ticket, e.g. `Giải Nhất`.
  final String name;

  /// The amount in đồng.
  final int amount;
}

const _dacBiet = Prize('Giải Đặc biệt', 2000000000);
const _mayMan = Prize('Giải may mắn', 50000000);
const _khuyenKhich = Prize('Giải khuyến khích', 6000000);

// Each tier below Đặc biệt: its prize, how many numbers it has and how many
// last digits of the ticket must match. Listed in the order the winning
// numbers come in.
const _tiers = <(Prize, int, int)>[
  (Prize('Giải Nhất', 30000000), 1, 5),
  (Prize('Giải Nhì', 15000000), 1, 5),
  (Prize('Giải Ba', 10000000), 2, 5),
  (Prize('Giải Tư', 3000000), 7, 5),
  (Prize('Giải Năm', 1000000), 1, 4),
  (Prize('Giải Sáu', 400000), 3, 4),
  (Prize('Giải Bảy', 200000), 1, 3),
  (Prize('Giải Tám', 100000), 1, 2),
];

/// Every prize [ticketNumber] wins against one province's [winningNumbers].
///
/// [ticketNumber] is six digits, kept as text so a leading zero stays.
/// [winningNumbers] are the 18 numbers in order from Đặc biệt down to Giải
/// Tám. The rules are in `docs/PRIZES.md`. No prize gives an empty list.
List<Prize> prizesWon(String ticketNumber, List<String> winningNumbers) {
  final special = winningNumbers.first;
  final prizes = <Prize>[];

  if (ticketNumber == special) {
    prizes.add(_dacBiet);
  } else if (_endsLike(ticketNumber, special, 5)) {
    prizes.add(_mayMan);
  } else if (_differsByOneDigit(ticketNumber, special)) {
    prizes.add(_khuyenKhich);
  }

  var next = 1;
  for (final (prize, count, digits) in _tiers) {
    for (final number in winningNumbers.skip(next).take(count)) {
      if (_endsLike(ticketNumber, number, digits)) prizes.add(prize);
    }
    next += count;
  }
  return prizes;
}

bool _endsLike(String ticketNumber, String winning, int digits) =>
    ticketNumber.endsWith(winning.substring(winning.length - digits));

bool _differsByOneDigit(String ticketNumber, String special) {
  if (ticketNumber.length != special.length) return false;
  var differing = 0;
  for (var i = 0; i < special.length; i++) {
    if (ticketNumber[i] != special[i]) differing++;
  }
  return differing == 1;
}
