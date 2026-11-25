import 'package:flutter/material.dart';
import 'auth_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9), // Vert très clair éco-conception
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icône / Logo Green IT
              const Icon(
                Icons.devices_other,
                size: 90,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 24),
              const Text(
                'EcoRepair',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Don, prêt et diagnostic de matériel informatique pour une tech durable.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const Spacer(),
              // Bouton Commencer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Navigation vers la page de Connexion / Inscription
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthPage()),
                    );
                  },
                  child: const Text(
                    'Commencer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}