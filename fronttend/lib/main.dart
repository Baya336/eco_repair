import 'package:flutter/material.dart';
import 'pages/welcomepage.dart';

void main() {
  runApp(const EcoRepairApp());
}

class EcoRepairApp extends StatelessWidget {
  const EcoRepairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRepair',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      // C'est ici que démarre l'application :
      home: const WelcomePage(),
    );
  }
}