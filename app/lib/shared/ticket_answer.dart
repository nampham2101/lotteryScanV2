import 'prize_check.dart';
import 'results_feed.dart';
import 'ticket_fields.dart';

/// What checking a ticket against the feed gives. Each one has its own screen.
sealed class TicketAnswer {
  const TicketAnswer();
}

/// The ticket wins [prizes], the highest amount first.
class Won extends TicketAnswer {
  const Won(this.prizes);

  final List<Prize> prizes;
}

/// The ticket's draw is in the feed and it wins nothing.
class Lost extends TicketAnswer {
  const Lost();
}

/// The ticket's draw is after the feed's newest day. [drawDay] is the
/// ticket's own date, and [isToday] is true when it is today.
class NotDrawnYet extends TicketAnswer {
  const NotDrawnYet({required this.drawDay, required this.isToday});

  /// As `DD/MM/YYYY`.
  final String drawDay;
  final bool isToday;
}

/// The ticket's date is before the feed's oldest day.
class TooOld extends TicketAnswer {
  const TooOld();
}

/// The answer for [fields] against the feed's [days], or null when the
/// ticket's date is in the feed but its province isn't listed that day, which
/// is screen 4d. [now] is today's date, which only tells 4c's two wordings
/// apart.
TicketAnswer? answerFor(
  TicketFields fields,
  List<DrawDay> days, {
  DateTime? now,
}) {
  final date = _ticketDate(fields.date);
  final dates = days.map((day) => day.date).toList()..sort();
  if (date.isAfter(dates.last)) {
    final today = now ?? DateTime.now();
    return NotDrawnYet(
      drawDay: slashedDate(fields.date),
      isToday: date == DateTime.utc(today.year, today.month, today.day),
    );
  }
  if (date.isBefore(dates.first)) return const TooOld();
  final numbers = _numbersOn(date, fields.province, days);
  if (numbers == null) return null;
  final prizes = prizesWon(fields.number, numbers);
  if (prizes.isEmpty) return const Lost();
  return Won([...prizes]..sort((a, b) => b.amount.compareTo(a.amount)));
}

/// `30-10-2026` as `30/10/2026`.
String slashedDate(String ddMmYyyy) => ddMmYyyy.replaceAll('-', '/');

DateTime _ticketDate(String ddMmYyyy) {
  final parts = ddMmYyyy.split('-').map(int.parse).toList();
  return DateTime.utc(parts[2], parts[1], parts[0]);
}

List<String>? _numbersOn(DateTime date, String province, List<DrawDay> days) {
  final names = _feedNames(province);
  for (final day in days.where((day) => day.date == date)) {
    for (final name in names) {
      final numbers = day.provinces[name];
      if (numbers != null) return numbers;
    }
  }
  return null;
}

/// The names the feed may use for a ticket's province: it has no "TP. ", and
/// writes Lâm Đồng for Đà Lạt.
List<String> _feedNames(String province) => [
  province.replaceFirst('TP. ', ''),
  if (province == 'Đà Lạt') 'Lâm Đồng',
];

/// 6000000 as `6.000.000đ`.
String formatMoney(int amount) {
  final digits = amount.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return (grouped..write('đ')).toString();
}
