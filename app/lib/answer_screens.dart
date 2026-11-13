import 'package:flutter/material.dart';

import 'reading_screen.dart';
import 'shared/answer_movement.dart';
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
const _iconSize = 56.0;

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
      winksOnce: true,
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
    this.winksOnce = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final TicketCard? card;

  /// Only 4b: its smiley winks once after it opens.
  final bool winksOnce;

  @override
  Widget build(BuildContext context) {
    return ResultLayout(
      icon: icon,
      iconColor: iconColor,
      iconBuilder: winksOnce
          ? (icon, size, color) =>
                WinkingSmiley(icon: icon, size: size, color: color)
          : null,
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
/// scrolls when the blocks don't fit. When it opens, the icon, the title and
/// each amount pop in one after another and confetti bursts from the icon.
class WonScreen extends StatefulWidget {
  const WonScreen({required this.prizes, required this.card, super.key});

  final List<Prize> prizes;
  final TicketCard card;

  @override
  State<WonScreen> createState() => _WonScreenState();
}

class _WonScreenState extends State<WonScreen>
    with SingleTickerProviderStateMixin {
  // The icon and the title pop in first, then one amount per prize.
  late final _clock = CelebrationClock(this, popCount: 2 + widget.prizes.length)
    ..play();
  final _iconLink = LayerLink();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wonBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _content()),
            // Over everything, so the confetti falls in front of the card.
            CompositedTransformFollower(
              link: _iconLink,
              showWhenUnlinked: false,
              child: SizedBox.square(
                dimension: _iconSize,
                child: ConfettiBurst(clock: _clock),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return LayoutBuilder(
      builder: (context, screen) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          // Centred when it fits, as the sketch has it.
          constraints: BoxConstraints(minHeight: screen.maxHeight - 48),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CompositedTransformTarget(
                  link: _iconLink,
                  child: PopIn(
                    clock: _clock,
                    place: 0,
                    child: const ExcludeSemantics(
                      child: Icon(
                        Icons.celebration,
                        size: _iconSize,
                        color: _wonDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PopIn(
                  clock: _clock,
                  place: 1,
                  child: const Text(
                    'Chúc mừng!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _wonDark,
                    ),
                  ),
                ),
                for (final (i, prize) in widget.prizes.indexed)
                  _PrizeBlock(prize, clock: _clock, place: 2 + i),
                const SizedBox(height: 20),
                TicketCard(
                  number: widget.card.number,
                  province: widget.card.province,
                  date: widget.card.date,
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
    );
  }
}

class _PrizeBlock extends StatelessWidget {
  const _PrizeBlock(this.prize, {required this.clock, required this.place});

  final Prize prize;
  final CelebrationClock clock;
  final int place;

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
          PopIn(
            clock: clock,
            place: place,
            child: Text(
              formatMoney(prize.amount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _wonDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
