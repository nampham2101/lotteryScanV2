import 'package:flutter/material.dart';

import 'reading_screen.dart';
import 'shared/open_camera.dart';
import 'shared/prize_check.dart';
import 'shared/result_layout.dart';
import 'shared/ticket_answer.dart';
import 'shared/ticket_fields.dart';

const _brown = Color(0xFF8A5A12);
const _alertRed = Color(0xFFB3261E);
const _wonBackground = Color(0xFFE8F0DD);
const _wonDark = Color(0xFF2D5A0E);
const _wonGreen = Color(0xFF3B7A12);
const _drawTime = '16:15';

/// The screen for [answer], the answer of the ticket with [fields].
Widget answerScreenFor(TicketAnswer answer, TicketFields fields) {
  final card = TicketCard(
    number: fields.number,
    province: fields.province,
    date: slashedDate(fields.date),
  );
  return switch (answer) {
    Won(:final prizes) => WonScreen(prizes: prizes, card: card),
    Lost() => _OpensCameraScreen(
      icon: Icons.sentiment_satisfied_alt,
      iconColor: resultHintColor,
      title: 'Chưa trúng lần này',
      message: 'Chúc bạn may mắn lần sau!',
      card: card,
    ),
    NotDrawnYet(:final drawDay, :final isToday) => _OpensCameraScreen(
      icon: Icons.schedule,
      iconColor: _brown,
      title: 'Chưa có kết quả',
      message:
          'Xổ số ${fields.province} mở thưởng lúc $_drawTime'
          '${isToday ? '' : ' ngày $drawDay'}. Quay lại sau nhé.',
      card: card,
    ),
    TooOld() => const _OpensCameraScreen(
      icon: Icons.schedule,
      iconColor: _brown,
      title: 'Vé quá cũ',
      message: 'Chỉ dò được vé trong 5 kỳ quay gần nhất.',
    ),
  };
}

/// A result screen whose "Quét vé khác" opens the camera in its place. If the
/// camera won't start, the home screen shows with the reason, as on 4d. The
/// phone's back closes it, which shows the home screen.
class _OpensCameraScreen extends StatelessWidget {
  const _OpensCameraScreen({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.card,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final TicketCard? card;

  @override
  Widget build(BuildContext context) {
    return ResultLayout(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      card: card,
      buttonLabel: 'Quét vé khác',
      onPressed: () => openTicketCamera(context, replaceScreen: true),
    );
  }
}

/// "Couldn't load": no internet, no answer in time or a feed we can't read.
/// "Thử lại" checks the same ticket again.
class CouldNotLoadScreen extends StatelessWidget {
  const CouldNotLoadScreen({required this.fields, super.key});

  final TicketFields fields;

  @override
  Widget build(BuildContext context) {
    return ResultLayout(
      icon: Icons.wifi_off,
      iconColor: _alertRed,
      title: 'Không tải được kết quả',
      message: 'Kiểm tra kết nối mạng rồi thử lại sau.',
      buttonLabel: 'Thử lại',
      onPressed: () {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ReadingScreen.check(fields: fields),
          ),
        );
      },
    );
  }
}

/// Sketch 4a: one block per prize won, the highest first, with no total. It
/// scrolls when the blocks don't fit.
class WonScreen extends StatelessWidget {
  const WonScreen({required this.prizes, required this.card, super.key});

  final List<Prize> prizes;
  final TicketCard card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wonBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, screen) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              // Centred when it fits, as the sketch has it.
              constraints: BoxConstraints(minHeight: screen.maxHeight - 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(Icons.celebration, size: 56, color: _wonDark),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chúc mừng!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _wonDark,
                      ),
                    ),
                    for (final prize in prizes) _PrizeBlock(prize),
                    const SizedBox(height: 20),
                    TicketCard(
                      number: card.number,
                      province: card.province,
                      date: card.date,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    ResultButton(
                      label: 'Quét vé khác',
                      onPressed: () =>
                          openTicketCamera(context, replaceScreen: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrizeBlock extends StatelessWidget {
  const _PrizeBlock(this.prize);

  final Prize prize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            'Bạn trúng ${prize.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: _wonGreen),
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(prize.amount),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: _wonDark,
            ),
          ),
        ],
      ),
    );
  }
}
