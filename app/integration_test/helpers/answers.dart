// The words on the screens that show a ticket's answer, word for word, since
// ticket #31 replaced the temporary screen with the sketched screens: sketch 3
// while the ticket is read and the feed loads, then 4a, 4b, 4c, "too old" or
// "couldn't load" (4d's words are in ticket_fields.dart). Shared by ticket
// #31's tests and the older tests it changed. Only the tests on the Mac use
// this, so it must not import Flutter.

/// Sketch 3. The ticket writes the title with one "…" character; the app wrote
/// three dots before ticket #31. A person can't tell them apart, so both pass.
const readingTitle = 'Đang đọc vé…';
const readingTitleWithDots = 'Đang đọc vé...';
const readingHint = 'Chỉ mất vài giây';

/// What the two ways of writing the title start with.
const readingTitleStart = 'Đang đọc vé';

/// 4a.
const wonTitle = 'Chúc mừng!';
String wonLine(String prize) => 'Bạn trúng $prize';

/// 4b.
const lostTitle = 'Chưa trúng lần này';
const lostHint = 'Chúc bạn may mắn lần sau!';

/// 4c. [date] is DD/MM/YYYY, given when the draw isn't today.
const notDrawnTitle = 'Chưa có kết quả';
String notDrawnHint(String province, {String? date}) => date == null
    ? 'Xổ số $province mở thưởng lúc 16:15. Quay lại sau nhé.'
    : 'Xổ số $province mở thưởng lúc 16:15 ngày $date. Quay lại sau nhé.';

/// "Too old", in 4d's layout.
const tooOldTitle = 'Vé quá cũ';
const tooOldHint = 'Chỉ dò được vé trong 5 kỳ quay gần nhất.';

/// "Couldn't load", in 4d's layout.
const couldNotLoadTitle = 'Không tải được kết quả';
const couldNotLoadHint = 'Kiểm tra kết nối mạng rồi thử lại sau.';

const scanAnotherLabel = 'Quét vé khác';

/// The ticket card on 4a, 4b and 4c. [date] is DD/MM/YYYY.
String ticketCard({
  required String number,
  required String province,
  required String date,
}) => 'Vé $number · $province · $date';

/// A ticket's date as ML Kit reads it, DD-MM-YYYY, the way the card writes
/// it, DD/MM/YYYY.
String cardDate(String ddMmYyyy) => ddMmYyyy.replaceAll('-', '/');

/// The title of every answer screen but 4d.
const answerTitles = [
  wonTitle,
  lostTitle,
  notDrawnTitle,
  tooOldTitle,
  couldNotLoadTitle,
];
