
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late TabController _tabController;

  bool _isLoading = false;
  String? _error;

  List<dynamic> _myReservations = [];
  List<dynamic> _receivedReservations = [];

  static const Color navy = Color.fromRGBO(5, 21, 44, 1);
  static const Color green = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Chargement des réservations envoyées et reçues
  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<List<dynamic>>([
        _authService.getMyReservations(),
        _authService.getReceivedReservations(),
      ]);

      if (!mounted) return;

      setState(() {
        _myReservations = results[0];
        _receivedReservations = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Traduction des statuts
  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'annulee':
        return 'Annulée';
      case 'terminee':
        return 'Terminée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'acceptee':
        return green;
      case 'refusee':
      case 'annulee':
        return Colors.red;
      case 'terminee':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // Exécution d'une action puis actualisation des réservations
  Future<void> _performAction(
    Future<dynamic> Function() action,
  ) async {
    try {
      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opération effectuée avec succès.'),
        ),
      );

      await _loadReservations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // Récupération sécurisée d'une valeur
  String _getText(dynamic value, [String fallback = 'Non renseigné']) {
    if (value == null || value.toString().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  // Récupération de l'identifiant de réservation
  int _getReservationId(Map<String, dynamic> reservation) {
    return int.tryParse(
          reservation['id']?.toString() ?? '',
        ) ??
        0;
  }

  // Affichage d'une réservation
  Widget _buildReservationCard(
    dynamic item, {
    required bool isReceived,
  }) {
    final reservation = Map<String, dynamic>.from(item as Map);

    final int reservationId = _getReservationId(reservation);

    final String status = _getText(
      reservation['statut'],
      'en_attente',
    );

    final List<dynamic> articles =
        reservation['articles'] is List
            ? reservation['articles']
            : [];

    String articleTitle = 'Article non renseigné';

    if (articles.isNotEmpty && articles.first is Map) {
      final article = Map<String, dynamic>.from(
        articles.first as Map,
      );

      articleTitle = _getText(
        article['titre'] ??
            article['nom_materiel'] ??
            article['title'],
        'Article sans titre',
      );
    }

    final String date = _getText(
      reservation['date_reservation'] ??
          reservation['date_creation'] ??
          reservation['created_at'],
    );

    final String beneficiary = reservation['beneficiaire'] is Map
        ? _getText(
            reservation['beneficiaire']['nom'] ??
                reservation['beneficiaire']['username'] ??
                reservation['beneficiaire']['email'],
          )
        : _getText(reservation['beneficiaire']);

    final bool donorConfirmed =
        reservation['confirmation_donneur'] == true;

    final bool beneficiaryConfirmed =
        reservation['confirmation_beneficiaire'] == true;

    final bool isAccepted = status.toLowerCase() == 'acceptee';
    final bool isPending = status.toLowerCase() == 'en_attente';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    articleTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Date : $date',
                    style: const TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Bénéficiaire pour les demandes reçues
            if (isReceived) ...[
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 17,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bénéficiaire : $beneficiary',
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Confirmation du retrait
            if (isAccepted) ...[
              const Divider(height: 20),
              const Text(
                'Confirmation du retrait',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              _buildConfirmationLine(
                'Donneur',
                donorConfirmed,
              ),
              const SizedBox(height: 5),
              _buildConfirmationLine(
                'Bénéficiaire',
                beneficiaryConfirmed,
              ),
            ],

            const SizedBox(height: 12),

            // Boutons pour les demandes reçues en attente
            if (isReceived && isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: reservationId == 0
                          ? null
                          : () => _performAction(
                                () => _authService.acceptReservation(
                                  reservationId,
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accepter'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: reservationId == 0
                          ? null
                          : () => _performAction(
                                () => _authService.refuseReservation(
                                  reservationId,
                                ),
                              ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Refuser'),
                    ),
                  ),
                ],
              ),
            ],

            // Bouton de confirmation du retrait
            if (isAccepted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: reservationId == 0 ||
                          (isReceived
                              ? donorConfirmed
                              : beneficiaryConfirmed)
                      ? null
                      : () => _performAction(
                            () => _authService.confirmHandover(
                              reservationId,
                            ),
                          ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    isReceived
                        ? (donorConfirmed
                            ? 'Retrait déjà confirmé'
                            : 'Confirmer le retrait')
                        : (beneficiaryConfirmed
                            ? 'Retrait déjà confirmé'
                            : 'Confirmer la réception'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationLine(
    String role,
    bool confirmed,
  ) {
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle : Icons.pending,
          color: confirmed ? green : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '$role : ${confirmed ? 'Confirmé' : 'En attente'}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  // Affichage d'une liste de réservations
  Widget _buildReservationList(
    List<dynamic> reservations, {
    required bool isReceived,
  }) {
    if (reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy,
                size: 55,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                isReceived
                    ? 'Aucune demande reçue.'
                    : 'Vous n’avez pas encore effectué de réservation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 20,
        ),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(
            reservations[index],
            isReceived: isReceived,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(

          'Mes réservations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: green,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.shopping_bag_outlined),
              text: 'Mes demandes',
            ),
            Tab(
              icon: Icon(Icons.inbox_outlined),
              text: 'Demandes reçues',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: green,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadReservations,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReservationList(
                      _myReservations,
                      isReceived: false,
                    ),
                    _buildReservationList(
                      _receivedReservations,
                      isReceived: true,
                    ),
                  ],
                ),
    );
  }
}
