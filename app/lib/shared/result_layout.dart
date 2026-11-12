import 'package:flutter/material.dart';

const resultTitleColor = Color(0xFF222222);
const resultHintColor = Color(0xFF555555);
const resultButtonBlue = Color(0xFF1A5FA6);
const _cardColor = Color(0xFFF0EDE6);

/// The ticket card of sketches 4a to 4c, e.g. `Vé 123456 · Bến Tre · 03/11/2026`.
/// [color] is beige-grey on a white screen and white on 4a's green one.
class TicketCard extends StatelessWidget {
  const TicketCard({
    required this.number,
    required this.province,
    required this.date,
    this.color = _cardColor,
    super.key,
  });

  final String number;
  final String province;

  /// As `DD/MM/YYYY`.
  final String date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Vé $number · $province · $date',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: resultTitleColor),
      ),
    );
  }
}

/// The blue button of the result screens.
class ResultButton extends StatelessWidget {
  const ResultButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: resultButtonBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// The layout of sketches 4b, 4c and 4d, also used by "too old" and "couldn't
/// load": an icon, a title, a line, an optional ticket [card] and a button,
/// in the middle of a white screen.
class ResultLayout extends StatelessWidget {
  const ResultLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    this.card,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final TicketCard? card;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(child: Icon(icon, size: 56, color: iconColor)),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: resultTitleColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: resultHintColor),
                ),
                if (card != null) ...[const SizedBox(height: 20), card!],
                const SizedBox(height: 24),
                ResultButton(label: buttonLabel, onPressed: onPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
