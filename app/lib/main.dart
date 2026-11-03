import 'package:flutter/material.dart';

void main() {
  runApp(const LotteryScanApp());
}

class LotteryScanApp extends StatelessWidget {
  const LotteryScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Dò Vé Số', home: Scaffold());
  }
}
