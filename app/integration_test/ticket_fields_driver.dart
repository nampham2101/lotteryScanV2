import 'package:flutter_driver/flutter_driver.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'helpers/driven_app.dart';
import 'helpers/photo_screen.dart';
import 'helpers/ticket_fields.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #24, on the Pixel_10 emulator. They run on the
// Mac, because only the Mac can read the kept photo and compare it with the
// screen. They talk to the real app started from ticket_text_app.dart, where
// the tests decide what ML Kit's text is and when the read finishes. Run them
// from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/ticket_fields_driver.dart \
//     --target=integration_test/ticket_text_app.dart
//
// Each test starts from the home screen, so they can run one at a time. Don't
// touch the emulator during a run.
//
// ML Kit's answer gives its blocks in the opposite order to its text, so a
// rule that searched the blocks instead of the text would find the wrong
// "first" match.

/// Given: a photo was just taken, and ML Kit's read of it finishes with
/// [text]. Returns the photo.
Future<img.Image> whenReadFinishesWith(String text) async {
  final photo = await givenReadingShows();
  await finishRead(0, text);
  return photo;
}

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  setUp(holdReads);

  group('Normal case', () {
    test('Given the photo\'s ML Kit text has 871723, "BẠC LIEUOL0T010b" and '
        '20-10-2026, when the read finishes, then the temporary screen shows '
        'the photo with exactly three lines below it, in this order from top '
        'to bottom, "Số vé: 871723", "Tỉnh: Bạc Liêu" and "Ngày: 20-10-2026", '
        'and none of ML Kit\'s own text', () async {
      final photo = await whenReadFinishesWith(
        'XỔ SỐ KIẾN THIẾT\n'
        'BẠC LIEUOL0T010b\n'
        'LOẠI VÉ 10.000Đ\n'
        '20-10-2026\n'
        '871723',
      );

      await expectOnlyLinesAre(
        fieldLines(number: '871723', province: 'Bạc Liêu', date: '20-10-2026'),
      );
      await expectScreenShows(photo);
      await expectReadWasOfKeptPhoto(0);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the shutter was just tapped, when the read hasn\'t finished, '
        'then the screen shows the photo and "Đang đọc vé..." as it does '
        'today', () async {
      await givenCameraScreenOpen();

      final tappedAt = await tapShutter();

      await expectPhotoScreenOpensWithoutHome();
      await expectOnlyTextIs(readingText);
      await expectScreenShows(await keptPhotoSince(tappedAt));
      await expectReadAsked(0);
      expect((await readerReport()).reads.single.isFinished, isFalse);
    }, timeout: testTimeout);
  });

  group('Number', () {
    test('Given the only six digits sit in "C871723", when the read finishes, '
        'then the screen shows "Số vé: 871723"', () async {
      await whenReadFinishesWith('BẠC LIÊU\nC871723\n20-10-2026');

      await expectFieldShows(numberLabel, '871723');
    }, timeout: testTimeout);

    test('Given 9999999999 comes before any other digits, when the read '
        'finishes, then the screen shows "Số vé: 999999"', () async {
      await whenReadFinishesWith('BẠC LIÊU\n9999999999\n871723\n20-10-2026');

      await expectFieldShows(numberLabel, '999999');
    }, timeout: testTimeout);

    test('Given 871723 comes before "C871733", when the read finishes, then '
        'the screen shows "Số vé: 871723"', () async {
      await whenReadFinishesWith('BẠC LIÊU\n871723\nC871733\n20-10-2026');

      await expectFieldShows(numberLabel, '871723');
    }, timeout: testTimeout);

    test('Given the text has a province and a valid date, and the only other '
        'digits are "D051 669", split by a space, when the read finishes, then '
        'the screen shows "Số vé: 051669"', () async {
      await whenReadFinishesWith('CẦN THƠ\n04-11-2026\nD051 669');

      await expectFieldShows(numberLabel, '051669');
    }, timeout: testTimeout);

    test('Given one line is "12" and the next line is "871723", when the read '
        'finishes, then the screen shows "Số vé: 871723"', () async {
      await whenReadFinishesWith('BẠC LIÊU\n12\n871723\n20-10-2026');

      await expectFieldShows(numberLabel, '871723');
    }, timeout: testTimeout);
  });

  group('Province', () {
    test('Given the text has "VINH LONG", with no accents and in upper case, '
        'when the read finishes, then the screen shows "Tỉnh: Vĩnh '
        'Long"', () async {
      await whenReadFinishesWith(
        'XỔ SỐ KIẾN THIẾT\nVINH LONG\n123456\n30-10-2026',
      );

      await expectFieldShows(provinceLabel, 'Vĩnh Long');
    }, timeout: testTimeout);

    test('Given "CẢN THƠ" comes before "VINH LONG", when the read finishes, '
        'then the screen shows "Tỉnh: Cần Thơ"', () async {
      await whenReadFinishesWith('CẢN THƠ\nVINH LONG\n123456\n30-10-2026');

      await expectFieldShows(provinceLabel, 'Cần Thơ');
    }, timeout: testTimeout);

    test('Given the text has "DONG NAI", when the read finishes, then the '
        'screen shows "Tỉnh: Đồng Nai", so Đ counts as D', () async {
      await whenReadFinishesWith(
        'XỔ SỐ KIẾN THIẾT\nDONG NAI\n123456\n30-10-2026',
      );

      await expectFieldShows(provinceLabel, 'Đồng Nai');
    }, timeout: testTimeout);

    test('Given the text has "DA LAT", when the read finishes, then the '
        'screen shows "Tỉnh: Đà Lạt"', () async {
      await whenReadFinishesWith(
        'XỔ SỐ KIẾN THIẾT\nDA LAT\n123456\n24-11-2019',
      );

      await expectFieldShows(provinceLabel, 'Đà Lạt');
    }, timeout: testTimeout);

    test('Given the text has "LAM DONG" but not "DA LAT", when the read '
        'finishes, then 4d shows', () async {
      final photo = await whenReadFinishesWith(
        'XỔ SỐ KIẾN THIẾT\nLAM DONG\n123456\n24-11-2019',
      );

      await expect4dShows(photo);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the text has "HO CHI MINH", when the read finishes, then the '
        'screen shows "Tỉnh: TP. Hồ Chí Minh"', () async {
      await whenReadFinishesWith(
        'XỔ SỐ KIẾN THIẾT\nHO CHI MINH\n123456\n30-10-2026',
      );

      await expectFieldShows(provinceLabel, 'TP. Hồ Chí Minh');
    }, timeout: testTimeout);

    test('Given no name from the 21 is in the text, when the read finishes, '
        'then 4d shows', () async {
      final photo = await whenReadFinishesWith(
        'XỔ SỐ KIẾN THIẾT\nHÀ NỘI\n123456\n30-10-2026',
      );

      await expect4dShows(photo);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Date', () {
    test('Given the only date-like text is "O30- 10- 2026", when the read '
        'finishes, then the screen shows "Ngày: 30-10-2026"', () async {
      await whenReadFinishesWith('BẠC LIÊU\nO30- 10- 2026\n871723');

      await expectFieldShows(dateLabel, '30-10-2026');
    }, timeout: testTimeout);

    test('Given the text has "CN-24-11-2019", when the read finishes, then '
        'the screen shows "Ngày: 24-11-2019"', () async {
      await whenReadFinishesWith('ĐÀ LẠT\nCN-24-11-2019\n871723');

      await expectFieldShows(dateLabel, '24-11-2019');
    }, timeout: testTimeout);

    test('Given the only date-like text is "0311-2026", when the read '
        'finishes, then 4d shows', () async {
      final photo = await whenReadFinishesWith('BẠC LIÊU\n0311-2026\n871723');

      await expect4dShows(photo);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Sketch 4d', () {
    test('Given ML Kit returns no text, when the read finishes, then 4d '
        'shows, and the temporary screen\'s "Không đọc được vé" line is '
        'gone', () async {
      final photo = await whenReadFinishesWith('');

      await expect4dShows(photo);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the read fails, when the read finishes, then 4d shows, and '
        'the temporary screen\'s "Không đọc được vé" line is gone', () async {
      final photo = await givenReadingShows();

      await failRead(0);

      await expect4dShows(photo);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    // How 4d looks next to the sketch (a full screen, the red icon) is manual
    // step 1. This test checks what a person can read and tap on it.
    test('Given 4d shows, then it has no photo, "Không đọc được vé", "Chụp '
        'lại ở nơi đủ sáng, giữ vé phẳng và rõ nét." and a "Thử lại" button, '
        'top to bottom', () async {
      final photo = await whenReadFinishesWith('XỔ SỐ KIẾN THIẾT');

      await expect4dShows(photo);
    }, timeout: testTimeout);

    test('Given 4d shows, when "Thử lại" is tapped, then the camera screen '
        'opens', () async {
      final photo = await whenReadFinishesWith('');
      await expect4dShows(photo);

      await tapTryAgain();

      await expectCameraScreenOpensAndStays();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given 4d shows, when the phone\'s back button is pressed, then the '
        'camera screen opens', () async {
      final photo = await whenReadFinishesWith('');
      await expect4dShows(photo);

      await phone.pressBackButton();

      await expectCameraScreenOpensAndStays();
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });
}
