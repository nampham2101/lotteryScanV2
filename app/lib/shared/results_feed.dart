import 'dart:convert';
import 'dart:io';

/// The feed with the last draw days' winning numbers (ticket #28).
final feedAddress = Uri.parse('https://xskt.com.vn/rss-feed/mien-nam-xsmn.rss');

const _giveUpAfter = Duration(seconds: 10);

/// One draw day: every province drawn that day with its 18 winning numbers, in
/// order from Đặc biệt down to Giải Tám, as `prizesWon` takes them.
class DrawDay {
  const DrawDay(this.date, this.provinces);

  /// The day, in UTC so that days compare without time-zone surprises.
  final DateTime date;

  /// The province's name as the feed writes it, e.g. `Hồ Chí Minh`.
  final Map<String, List<String>> provinces;
}

/// Fetches the feed. Every call goes to the site: nothing is kept between
/// scans. Throws when there is no internet, the site gives no answer within 10
/// seconds, or the answer isn't a feed we understand.
Future<List<DrawDay>> fetchResults() async {
  final client = HttpClient();
  try {
    return await _fetch(client).timeout(_giveUpAfter);
  } finally {
    client.close(force: true);
  }
}

Future<List<DrawDay>> _fetch(HttpClient client) async {
  final request = await client.getUrl(feedAddress);
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('The site answered ${response.statusCode}');
  }
  return parseResults(await utf8.decodeStream(response));
}

final _item = RegExp(r'<item>(.*?)</item>', dotAll: true);
final _link = RegExp(r'<link>[^<]*/ngay-(\d{1,2})-(\d{1,2})-(\d{4})</link>');
final _description = RegExp(r'<description>(.*?)</description>', dotAll: true);
final _province = RegExp(r'\[([^\]]+)\]([^\[]*)');

/// Reads the feed's [xml] into its draw days, newest first as the feed lists
/// them. Throws a [FormatException] when it isn't a feed.
List<DrawDay> parseResults(String xml) {
  final days = [
    for (final item in _item.allMatches(xml)) _parseDay(item.group(1)!),
  ];
  if (days.isEmpty) throw const FormatException('The feed has no draw days');
  return days;
}

DrawDay _parseDay(String item) {
  // The year is only in the link: the title has day and month, and every
  // item's pubDate is the same day.
  final link = _link.firstMatch(item);
  final description = _description.firstMatch(item)?.group(1);
  if (link == null || description == null) {
    throw const FormatException('A draw day has no date or no numbers');
  }
  final date = DateTime.utc(
    int.parse(link.group(3)!),
    int.parse(link.group(2)!),
    int.parse(link.group(1)!),
  );
  return DrawDay(date, {
    for (final match in _province.allMatches(description))
      match.group(1)!.trim(): _parseNumbers(match.group(2)!),
  });
}

// Every line is `label: numbers joined by " - "`, except that the feed glues
// the 7th and 8th prizes: `7: 8078: 82` is Bảy `807` and Tám `82`.
final _special = RegExp(r'ĐB:\s*(\d{6})');
final _numbered = RegExp(r'^([1-6]):\s*(.+)$', multiLine: true);
final _sevenAndEight = RegExp(r'7:\s*(\d{3})\s*8:\s*(\d{2})');

List<String> _parseNumbers(String block) {
  final special = _special.firstMatch(block)?.group(1);
  final sevenAndEight = _sevenAndEight.firstMatch(block);
  if (special == null || sevenAndEight == null) {
    throw const FormatException('A province is missing a prize');
  }
  final numbers = [special];
  for (final line in _numbered.allMatches(block)) {
    numbers.addAll(line.group(2)!.split('-').map((n) => n.trim()));
  }
  numbers.addAll([sevenAndEight.group(1)!, sevenAndEight.group(2)!]);
  if (numbers.length != 18 || numbers.any((n) => int.tryParse(n) == null)) {
    throw const FormatException('A province does not have 18 numbers');
  }
  return numbers;
}
