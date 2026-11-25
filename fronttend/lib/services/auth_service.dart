
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static String? accessToken;

  // ==================================================
  // HEADERS AVEC AUTHENTIFICATION
  // ==================================================

  Map<String, String> get _headers {
    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception('Vous devez être connecté.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  // ==================================================
  // LECTURE DES RÉPONSES
  // ==================================================

  dynamic _decodeResponse(http.Response response) {
    dynamic data;

    try {
      data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};
    } catch (_) {
      throw Exception('Réponse du serveur invalide.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? data['detail'] ?? 'Une erreur est survenue.'
          : 'Une erreur est survenue.';

      throw Exception(message.toString());
    }

    return data;
  }

  // ==================================================
  // INSCRIPTION
  // ==================================================

  Future<Map<String, dynamic>> register({
    required String nom,
    required String email,
    required String password,
    required String adresse,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nom': nom,
        'email': email,
        'password': password,
        'adresse': adresse,
        'role': role,
      }),
    );

    final data = _decodeResponse(response);
    return Map<String, dynamic>.from(data);
  }

  // ==================================================
  // CONNEXION
  // ==================================================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = _decodeResponse(response);

    accessToken = data['access_token']?.toString();

    return Map<String, dynamic>.from(data);
  }



  // ==================================================
  // MOT DE PASSE OUBLIÉ
  // ==================================================

  // Demander l'envoi du code de récupération par e-mail
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = _decodeResponse(response);

    return Map<String, dynamic>.from(data);
  }

  // Vérifier le code et réinitialiser le mot de passe
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/reset-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );

    final data = _decodeResponse(response);

    return Map<String, dynamic>.from(data);
  }


  // ==================================================
  // ANNONCES
  // ==================================================

  Future<List<dynamic>> getAnnouncements() async {
    final response = await http.get(
      Uri.parse('$baseUrl/announcements/'),
      headers: _headers,
    );

    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception('Format de réponse des annonces invalide.');
  }

  // ==================================================
  // PANIER
  // ==================================================

  Future<List<dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cart/'),
      headers: _headers,
    );

    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception('Format de réponse du panier invalide.');
  }

  Future<Map<String, dynamic>> addToCart(
    int announcementId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/add/$announcementId'),
      headers: _headers,
    );

    final data = _decodeResponse(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  Future<Map<String, dynamic>> removeFromCart(
    int announcementId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/remove/$announcementId'),
      headers: _headers,
    );

    final data = _decodeResponse(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  Future<Map<String, dynamic>> clearCart() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/clear'),
      headers: _headers,
    );

    final data = _decodeResponse(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  // ==================================================
  // RÉSERVATIONS DE DONS
  // ==================================================

  // Envoyer une demande de réservation
  Future<Map<String, dynamic>> createReservation({
    required int announcementId,
    String? contact,
    String? creneauRetrait,
    DateTime? dateRetraitSouhaitee,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/'),
      headers: _headers,
      body: jsonEncode({
        'announcement_id': announcementId,
        'contact': contact,
        'creneau_retrait': creneauRetrait,
        'date_retrait_souhaitee':
            dateRetraitSouhaitee?.toIso8601String(),
      }),
    );

    final data = _decodeResponse(response);
    return Map<String, dynamic>.from(data);
  }

  // Récupérer mes réservations envoyées
  Future<List<dynamic>> getMyReservations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reservations/mes-reservations'),
      headers: _headers,
    );

    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception('Format des réservations invalide.');
  }

  // Récupérer les demandes reçues sur mes annonces
  Future<List<dynamic>> getReceivedReservations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reservations/recues'),
      headers: _headers,
    );

    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception('Format des demandes reçues invalide.');
  }

  // Accepter une réservation
  Future<Map<String, dynamic>> acceptReservation(
    int reservationId,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reservations/$reservationId/accepter'),
      headers: _headers,
    );

    final data = _decodeResponse(response);
    return Map<String, dynamic>.from(data);
  }

  // Refuser une réservation
  Future<Map<String, dynamic>> refuseReservation(
    int reservationId,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reservations/$reservationId/refuser'),
      headers: _headers,
    );

    final data = _decodeResponse(response);
    return Map<String, dynamic>.from(data);
  }

  // Confirmer le retrait (donneur ou bénéficiaire)
  Future<Map<String, dynamic>> confirmHandover(
    int reservationId,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/reservations/$reservationId/confirmer-retrait',
      ),
      headers: _headers,
    );

    final data = _decodeResponse(response);
    return Map<String, dynamic>.from(data);
  }

  // ==================================================
  // DEMANDES DE PRÊT
  // ==================================================

  Future<Map<String, dynamic>> createLoanRequest({
    required int announcementId,
    required DateTime dateDebut,
    required DateTime dateFin,
    required String motif,
    String? telephoneContact,
    String? emailContact,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loan-requests/'),
      headers: _headers,
      body: jsonEncode({
        'announcement_id': announcementId,
        'date_debut_souhaitee':
            dateDebut.toIso8601String().split('T').first,
        'date_fin_souhaitee':
            dateFin.toIso8601String().split('T').first,
        'motif': motif,
        'telephone_contact': telephoneContact,
        'email_contact': emailContact,
      }),
    );

    final data = _decodeResponse(response);
    return Map<String, dynamic>.from(data);
  }

  // ==================================================
  // DIAGNOSTIC ET PANNES
  // ==================================================

  Future<List<dynamic>> getFaults() async {
    final response = await http.get(
      Uri.parse('$baseUrl/faults/'),
    );

    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception('Format des pannes invalide.');
  }

  Future<List<dynamic>> searchFaults(String query) async {
    final uri = Uri.parse('$baseUrl/faults/search').replace(
      queryParameters: {'q': query},
    );

    final response = await http.get(uri);
    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception('Format des résultats de recherche invalide.');
  }

  Future<List<dynamic>> getFaultCauses(int faultId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/faults/$faultId/causes'),
    );

    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception('Format des causes invalide.');
  }

  Future<List<dynamic>> getSolutionsForFault(int faultId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/solutions/fault/$faultId'),
    );

    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception('Format des solutions invalide.');
  }

  Future<Map<String, dynamic>> getAvailableParts(
    int solutionId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/solutions/$solutionId/available-parts',
      ),
    );

    final data = _decodeResponse(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Format des pièces disponibles invalide.');
  }

  // ==================================================
  // ENREGISTREMENT D'UN DIAGNOSTIC
  // ==================================================

  Future<Map<String, dynamic>> createDiagnostic({
    int? faultId,
    required String descriptionObservee,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/diagnostics/'),
      headers: _headers,
      body: jsonEncode({
        'fault_id': faultId,
        'description_observee': descriptionObservee,
      }),
    );

    final data = _decodeResponse(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Format du diagnostic invalide.');
  }

  // Récupérer l'historique de mes diagnostics
  Future<List<dynamic>> getMyDiagnostics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/diagnostics/mes-diagnostics'),
      headers: _headers,
    );

    final data = _decodeResponse(response);

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw Exception(
      'Format de l’historique des diagnostics invalide.',
    );
  }

  // ==================================================
  // DASHBOARD ENVIRONNEMENTAL
  // ==================================================

  Future<Map<String, dynamic>> getEnvironmentalDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/environmental/dashboard'),
    );

    final data = _decodeResponse(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Format des données du Dashboard invalide.');
  }
}
