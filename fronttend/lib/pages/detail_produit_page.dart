
import 'package:flutter/material.dart';
import 'profil_page.dart';
import '../services/auth_service.dart';

class DetailProduitPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const DetailProduitPage({super.key, required this.item});

  @override
  State<DetailProduitPage> createState() => _DetailProduitPageState();
}

class _DetailProduitPageState extends State<DetailProduitPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _commentaireController =
      TextEditingController();

  final AuthService _authService = AuthService();

  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 7));

  final bool _estDisponible = true;

  bool _demandeValidee = false;
  bool _isSubmitting = false;

  int get _joursPret {
    final diff = _dateFin.difference(_dateDebut).inDays;
    return diff > 0 ? diff : 1;
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _choisirDate({required bool isDebut}) async {
    final DateTime initial = isDebut ? _dateDebut : _dateFin;

    final DateTime firstDate = isDebut
        ? DateTime.now()
        : _dateDebut.add(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;

          if (!_dateFin.isAfter(_dateDebut)) {
            _dateFin = _dateDebut.add(const Duration(days: 1));
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  // ==================================================
  // ENVOI DE LA DEMANDE AU BACKEND
  // ==================================================

  Future<void> _soumettreDemande(bool isDon) async {
    if (_isSubmitting || _demandeValidee) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Récupérer l'identifiant de l'annonce.
    // Depuis la page d'accueil : id
    // Depuis le panier : announcement_id
    final dynamic rawId =
        widget.item['announcement_id'] ?? widget.item['id'];

    final int? announcementId = int.tryParse(rawId?.toString() ?? '');

    if (announcementId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Impossible de retrouver l’identifiant de cette annonce.',
          ),
        ),
      );
      return;
    }

    final String contact = _contactController.text.trim();
    final String commentaire = _commentaireController.text.trim();
    final String nom = _nomController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (isDon) {
        // ==========================================
        // DEMANDE DE DON
        // POST /reservations/
        // ==========================================

        await _authService.createReservation(
          announcementId: announcementId,
          contact: contact,
          creneauRetrait: commentaire,
        );
      } else {
        // ==========================================
        // DEMANDE DE PRÊT
        // POST /loan-requests/
        // ==========================================

        final bool isEmail = contact.contains('@');

        await _authService.createLoanRequest(
          announcementId: announcementId,
          dateDebut: _dateDebut,
          dateFin: _dateFin,
          motif: commentaire,
          telephoneContact: isEmail ? null : contact,
          emailContact: isEmail ? contact : null,
        );
      }

      // Le serveur a confirmé l'enregistrement.
      if (!mounted) return;

      setState(() {
        _demandeValidee = true;
        _isSubmitting = false;

        // Ajouter la demande au suivi local.
        globalUserRequests.insert(0, {
          'title': widget.item['name'] ?? 'Annonce',
          'type': isDon ? 'Don' : 'Prêt',
          'date': isDon
              ? 'Créneau souhaité : $commentaire'
              : 'Du ${_formatDate(_dateDebut)} au ${_formatDate(_dateFin)}',
          'status': 'En attente de validation',
          'statusColor': const Color(0xFFFFA726),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          content: Text(
            isDon
                ? 'Votre demande de don a été enregistrée !'
                : 'Votre demande de prêt a été enregistrée !',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Erreur lors de l’envoi : ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _contactController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isSmallScreen = screenWidth < 380;

    final bool isDon = widget.item['type'] == 'Don';
    final bool hasImage = widget.item['image'] != null;

    final String location =
        (widget.item['location'] ?? 'Campus Évry').toString();

    final String co2 =
        (widget.item['co2Saved'] ?? widget.item['co2'] ?? '156 kg CO₂')
            .toString();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(5, 21, 44, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isDon ? 'DÉTAILS DU DON' : 'DÉTAILS DU PRÊT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 15.5 : 17,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: screenWidth,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F2647),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 14.0 : 20.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ==========================================
                          // 1. CARTE RÉCAPITULATIVE DU PRODUIT
                          // ==========================================

                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDon
                                            ? const Color(0xFF2E7D32)
                                            : Colors.indigo,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isDon
                                            ? 'DON SOLIDAIRE'
                                            : 'PRÊT TEMPORAIRE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _estDisponible
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _estDisponible
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            size: 13,
                                            color: _estDisponible
                                                ? const Color(0xFF2E7D32)
                                                : Colors.redAccent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _estDisponible
                                                ? 'Disponible'
                                                : 'Indisponible',
                                            style: TextStyle(
                                              color: _estDisponible
                                                  ? const Color(0xFF2E7D32)
                                                  : Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '-$co2',
                                        style: const TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  height: (screenSize.height * 0.18).clamp(
                                    115.0,
                                    170.0,
                                  ),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(18),
                                    image: hasImage
                                        ? DecorationImage(
                                            image: AssetImage(
                                              widget.item['image'] as String,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: !hasImage
    ? Icon(
        widget.item['category']?.toString() == '1'
            ? Icons.memory
            : Icons.devices,
        size: isSmallScreen ? 52 : 64,
        color: const Color(0xFF2E7D32),
      )
    : null,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  widget.item['name'] as String? ?? 'Annonce',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (widget.item['repairScore'] != null) ...[
                                      const Icon(
                                        Icons.build_circle,
                                        size: 16,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Indice : ${widget.item['repairScore']}/10',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ] else if (widget.item['condition'] !=
                                        null) ...[
                                      const Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${widget.item['condition']}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Matériel vérifié et testé par l\'équipe EcoRepair. Prêt à l\'emploi pour réduire les déchets électroniques (DEEE).',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ==========================================
                          // 2. FORMULAIRE
                          // ==========================================

                          Text(
                            isDon
                                ? 'FORMULAIRE DE RETRAIT (DON)'
                                : 'FORMULAIRE DE DEMANDE DE PRÊT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 13 : 14,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isDon) ...[
                                  Container(
                                    padding: EdgeInsets.all(
                                      isSmallScreen ? 12 : 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Flexible(
                                              child: Text(
                                                'Période du prêt :',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2E7D32),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$_joursPret jour(s)',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildDateBox(
                                                label: 'Du',
                                                dateText: _formatDate(
                                                  _dateDebut,
                                                ),
                                                onTap: () => _choisirDate(
                                                  isDebut: true,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: isSmallScreen ? 8 : 10,
                                            ),
                                            Expanded(
                                              child: _buildDateBox(
                                                label: 'Au',
                                                dateText: _formatDate(_dateFin),
                                                onTap: () => _choisirDate(
                                                  isDebut: false,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                _buildField(
                                  controller: _nomController,
                                  label: 'Nom et Prénom',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _contactController,
                                  label: 'Téléphone ou E-mail universitaire',
                                  icon: Icons.contact_phone_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _commentaireController,
                                  label: isDon
                                      ? 'Créneau de passage souhaité (ex: Mardi 14h)'
                                      : 'Motif du prêt (ex: TP Réseaux, Projet M1...)',
                                  icon: isDon
                                      ? Icons.access_time
                                      : Icons.assignment_outlined,
                                ),
                                const SizedBox(height: 20),

                                // Bouton de validation
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          const Color(0xFF527A55),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: _isSubmitting || _demandeValidee
                                        ? null
                                        : () => _soumettreDemande(isDon),
                                    icon: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            isDon
                                                ? Icons.location_on
                                                : Icons.calendar_today,
                                            size: isSmallScreen ? 18 : 20,
                                          ),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _isSubmitting
                                            ? 'ENVOI EN COURS...'
                                            : _demandeValidee
                                                ? 'DEMANDE ENREGISTRÉE'
                                                : isDon
                                                    ? 'VALIDER & ENVOYER LA DEMANDE'
                                                    : 'CONFIRMER LA DEMANDE DE PRÊT',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ==========================================
                          // 3. CONFIRMATION APRÈS RÉPONSE DU SERVEUR
                          // ==========================================

                          if (_demandeValidee) ...[
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF4CAF50),
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'DEMANDE ENREGISTRÉE',
                                          style: TextStyle(
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isDon
                                        ? 'Votre demande de don pour ce matériel a bien été enregistrée. Le propriétaire doit maintenant valider votre demande.\n\n📍 Lieu indiqué : $location\n🕒 Créneau souhaité : ${_commentaireController.text}'
                                        : 'Votre demande de prêt a bien été enregistrée. Elle est en attente de validation par le propriétaire.\n\n📅 Du ${_formatDate(_dateDebut)} au ${_formatDate(_dateFin)}\n📍 Lieu indiqué : $location',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Demande enregistrée au nom de ${_nomController.text}.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // CHAMP DATE
  // ==================================================

  Widget _buildDateBox({
    required String label,
    required String dateText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event,
              color: Color(0xFF4CAF50),
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // CHAMPS DU FORMULAIRE
  // ==================================================

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Veuillez remplir ce champ';
        }

        return null;
      },
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white60,
          fontSize: 12.5,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF4CAF50),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
