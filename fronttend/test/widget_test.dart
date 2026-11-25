import 'package:flutter_test/flutter_test.dart';
import 'package:eco_repair/main.dart';

void main() {
  testWidgets('Test de démarrage EcoRepair', (WidgetTester tester) async {
    // Charge l'application EcoRepairApp au lieu de MyApp
    await tester.pumpWidget(const EcoRepairApp());
  });
}