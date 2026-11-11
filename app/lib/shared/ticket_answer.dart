import 'prize_check.dart';
import 'results_feed.dart';
import 'ticket_fields.dart';

const couldNotLoadLine = 'Không tải được kết quả, thử lại sau';

/// The lines to show below the three fields for [fields] against the feed's
/// [days], or null when the ticket's date is in the feed but its province
/// isn't listed that day, which is screen 4d.
List<String>? answerFor(TicketFields fields, List<DrawDay> days) {
  final date = _ticketDate(fields.date);
  final dates = days.map((day) => day.date).toList()..sort();
  if (date.isAfter(dates.last)) {
    return const ['Chưa có kết quả'];
  }
  if (date.isBefore(dates.first)) {
    return const ['Vé quá cũ, không dò được'];
  }
  final numbers = _numbersOn(date, fields.province, days);
  if (numbers == null) return null;
  final prizes = prizesWon(fields.number, numbers);
  if (prizes.isEmpty) return const ['Chưa trúng lần này'];
  return [
    'Chúc mừng! Bạn trúng',
    for (final prize in prizes) '${prize.name}: ${_money(prize.amount)}',
  ];
}

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
String _money(int amount) {
  final digits = amount.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return (grouped..write('đ')).toString();
}
