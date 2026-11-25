
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  // RÉCUPÉRER TOUS LES APPAREILS
  Future<List<dynamic>> getDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Erreur lors du chargement des appareils'
      );
    }

    return List<dynamic>.from(data);
  }

  // RECHERCHER UN APPAREIL
  Future<List<dynamic>> searchDevices(String query) async {
    final uri = Uri.parse('$baseUrl/devices/search')
        .replace(queryParameters: {'q': query});

    final response = await http.get(uri);

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Erreur lors de la recherche'
      );
    }

    return List<dynamic>.from(data);
  }

  // RÉCUPÉRER UN APPAREIL PAR SON ID
  Future<Map<String, dynamic>> getDeviceById(int deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices/$deviceId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Appareil introuvable'
      );
    }

    return Map<String, dynamic>.from(data);
  }
}
