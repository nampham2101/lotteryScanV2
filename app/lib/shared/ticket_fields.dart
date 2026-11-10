/// The three fields read from a ticket's ML Kit text.
class TicketFields {
  const TicketFields({
    required this.number,
    required this.province,
    required this.date,
  });

  /// Six digits, as printed.
  final String number;

  /// The province's name as written in the list of 21.
  final String province;

  /// As `DD-MM-YYYY`.
  final String date;
}

// The 21 names as shown on screen, each with the words that are matched. The
// words are already without accents and spaces, in lower case.
const _provinces = <(String, String)>[
  ('An Giang', 'angiang'),
  ('Bạc Liêu', 'baclieu'),
  ('Bến Tre', 'bentre'),
  ('Bình Dương', 'binhduong'),
  ('Bình Phước', 'binhphuoc'),
  ('Bình Thuận', 'binhthuan'),
  ('Cà Mau', 'camau'),
  ('Cần Thơ', 'cantho'),
  ('Đà Lạt', 'dalat'),
  ('Đồng Nai', 'dongnai'),
  ('Đồng Tháp', 'dongthap'),
  ('Hậu Giang', 'haugiang'),
  ('Kiên Giang', 'kiengiang'),
  ('Long An', 'longan'),
  ('Sóc Trăng', 'soctrang'),
  ('Tây Ninh', 'tayninh'),
  ('Tiền Giang', 'tiengiang'),
  ('TP. Hồ Chí Minh', 'hochiminh'),
  ('Trà Vinh', 'travinh'),
  ('Vĩnh Long', 'vinhlong'),
  ('Vũng Tàu', 'vungtau'),
];

final _number = RegExp(r'\d{6}');
final _date = RegExp(r'\d{2}-\d{2}-\d{4}');

// Every lower-case Latin letter that Unicode builds from a plain letter and
// marks (Latin-1, Latin Extended-A and B, Latin Extended Additional), next to
// the plain letter it becomes. Dart has no built-in way to take marks off.
const _lettersWithMarks =
    'àáâãäåçèéêëìíîïñòóôõöùúûüýÿāăąćĉċčďēĕėęěĝğġģĥĩīĭįĵķĺļľńņňōŏő'
    'ŕŗřśŝşšţťũūŭůűųŵŷźżžơưǎǐǒǔǖǘǚǜǟǡǧǩǫǭǰǵǹǻȁȃȅȇȉȋȍȏȑȓȕȗșțȟȧȩȫȭȯ'
    'ȱȳḁḃḅḇḉḋḍḏḑḓḕḗḙḛḝḟḡḣḥḧḩḫḭḯḱḳḵḷḹḻḽḿṁṃṅṇṉṋṍṏṑṓṕṗṙṛṝṟṡṣṥṧṩṫṭṯṱṳ'
    'ṵṷṹṻṽṿẁẃẅẇẉẋẍẏẑẓẕẖẗẘẙạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừử'
    'ữựỳỵỷỹ';
const _plainLetters =
    'aaaaaaceeeeiiiinooooouuuuyyaaaccccdeeeeegggghiiiijklllnnnooo'
    'rrrssssttuuuuuuwyzzzouaiouuuuuaagkoojgnaaaeeiioorruusthaeooo'
    'oyabbbcdddddeeeeefghhhhhiikkkllllmmmnnnnoooopprrrrsssssttttu'
    'uuuuvvwwwwwxxyzzzhtwyaaaaaaaaaaaaeeeeeeeeiioooooooooooouuuuu'
    'uuyyyy';

final _plainLetter = <String, String>{
  for (var i = 0; i < _lettersWithMarks.length; i++)
    _lettersWithMarks[i]: _plainLetters[i],
  // Not built from a plain letter and a mark, but read as D: Vietnamese Đ and
  // the Icelandic Ð, which looks the same.
  'đ': 'd',
  'ð': 'd',
};

// Accents written as separate marks after the letter.
final _separateMarks = RegExp('[̀-ͯ]');

/// Reads the number, the province and the date from ML Kit's [text], or
/// returns null when one is missing. The first match of each wins.
TicketFields? readTicketFields(String text) {
  // Spaces go within each line. Line breaks stay, so nothing joins across
  // lines.
  final lines = text
      .split(RegExp(r'\r\n|\r|\n'))
      .map((line) => line.replaceAll(RegExp(r'\s'), ''))
      .toList();
  final number = _number.firstMatch(lines.join('\n'))?.group(0);
  final date = _date.firstMatch(lines.join('\n'))?.group(0);
  final province = _findProvince(lines.map(_plain).join('\n'));
  if (number == null || date == null || province == null) return null;
  return TicketFields(number: number, province: province, date: date);
}

/// Lower case, no accents or marks on any Latin letter, Đ and Ð as D.
String _plain(String line) {
  final lower = line.toLowerCase().replaceAll(_separateMarks, '');
  return lower.split('').map((c) => _plainLetter[c] ?? c).join();
}

/// The name that starts first in [plain], the longer one when two start
/// together.
String? _findProvince(String plain) {
  String? found;
  var foundAt = -1;
  var foundLength = 0;
  for (final (name, words) in _provinces) {
    final at = plain.indexOf(words);
    if (at < 0) continue;
    if (found == null ||
        at < foundAt ||
        (at == foundAt && words.length > foundLength)) {
      found = name;
      foundAt = at;
      foundLength = words.length;
    }
  }
  return found;
}
