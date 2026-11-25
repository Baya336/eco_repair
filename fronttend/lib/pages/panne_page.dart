
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'detail_produit_page.dart';

class PannePage extends StatefulWidget {
  const PannePage({super.key});

  @override
  State<PannePage> createState() => _PannePageState();
}

class _PannePageState extends State<PannePage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  int _selectedSymptomIndex = 0;

  List<Map<String, dynamic>> _diagnostics = [];
  List<Map<String, dynamic>> _solutions = [];
  List<Map<String, dynamic>> _causes = [];
  List<Map<String, dynamic>> _partGroups = [];

  bool _isLoadingFaults = true;
  bool _isLoadingDetails = false;
  String? _errorMessage;

  final Color navy = const Color.fromRGBO(5, 21, 44, 1);
  final Color green = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
        _selectedSymptomIndex = 0;
      });
    });

    _loadFaults();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================================================
  // CHARGER LES PANNES DEPUIS LE BACKEND
  // ==================================================

  Future<void> _loadFaults() async {
    setState(() {
      _isLoadingFaults = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.getFaults();

      final faults = result.map((item) {
        final fault = Map<String, dynamic>.from(item);

        return {
          ...fault,
          'id': fault['id'],
          'symptom': fault['nom_panne'] ?? 'Panne sans nom',
          'shortLabel': fault['libelle_court'] ??
              fault['nom_panne'] ??
              'Panne',
          'icon': _getFaultIcon(
            fault['nom_panne']?.toString() ?? '',
          ),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _diagnostics = faults;
        _isLoadingFaults = false;
        _selectedSymptomIndex = 0;
      });

      if (faults.isNotEmpty) {
        await _loadFaultDetails(faults.first);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingFaults = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ==================================================
  // ICÔNES SELON LA PANNE
  // ==================================================

  IconData _getFaultIcon(String name) {
    final value = name.toLowerCase();

    if (value.contains('lent') || value.contains('blocage')) {
      return Icons.speed;
    }

    if (value.contains('écran') || value.contains('ecran')) {
      return Icons.desktop_access_disabled;
    }

    if (value.contains('chauff') || value.contains('température')) {
      return Icons.thermostat;
    }

    if (value.contains('batterie') || value.contains('charge')) {
      return Icons.battery_alert;
    }

    return Icons.troubleshoot;
  }

  // ==================================================
  // CHARGER LES SOLUTIONS, CAUSES ET PIÈCES
  // ==================================================

  Future<void> _loadFaultDetails(
    Map<String, dynamic> fault,
  ) async {
    final faultId = int.tryParse(fault['id'].toString());

    if (faultId == null) return;

    setState(() {
      _isLoadingDetails = true;
      _solutions = [];
      _causes = [];
      _partGroups = [];
    });

    try {
      final results = await Future.wait([
        _authService.getSolutionsForFault(faultId),
        _authService.getFaultCauses(faultId),
      ]);

      final solutions = results[0];
      final causes = results[1];

      final loadedSolutions = <Map<String, dynamic>>[];
      final loadedGroups = <Map<String, dynamic>>[];

      for (final solutionItem in solutions) {
        final solution = Map<String, dynamic>.from(solutionItem);

        loadedSolutions.add(solution);

        final solutionId = int.tryParse(
          solution['id'].toString(),
        );

        if (solutionId == null) continue;

        try {
          final partsResponse =
              await _authService.getAvailableParts(solutionId);

          final groups = partsResponse['pieces'];

          if (groups is List) {
            for (final groupItem in groups) {
              final group = Map<String, dynamic>.from(groupItem);

              final announcements = group['annonces'];

              loadedGroups.add({
                ...group,
                'solutionId': solutionId,
                'annonces': announcements is List
                    ? announcements
                        .map((a) => Map<String, dynamic>.from(a))
                        .toList()
                    : <Map<String, dynamic>>[],
              });
            }
          }
        } catch (e) {
          debugPrint('Erreur chargement des pièces : $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _solutions = loadedSolutions;
        _causes = causes
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _partGroups = loadedGroups;
        _isLoadingDetails = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingDetails = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ==================================================
  // DONNÉES DE LA SOLUTION
  // ==================================================

  String _solutionText(
    Map<String, dynamic> solution,
    String key,
    String fallback,
  ) {
    final value = solution[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  List<String> _solutionList(
    Map<String, dynamic> solution,
    String key,
  ) {
    final value = solution[key];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String && value.isNotEmpty) {
      return [value];
    }

    return [];
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return const Color(0xFF4CAF50);
      case 'moyen':
        return const Color(0xFFFFB300);
      case 'difficile':
        return Colors.redAccent;
      default:
        return Colors.lightBlueAccent;
    }
  }

  // ==================================================
  // PANNES FILTRÉES
  // ==================================================

  List<Map<String, dynamic>> get _filteredDiagnostics {
    return _diagnostics.where((diag) {
      final symptom =
          diag['symptom'].toString().toLowerCase();

      final shortLabel =
          diag['shortLabel'].toString().toLowerCase();

      final symptoms =
          (diag['symptomes'] ?? '').toString().toLowerCase();

      return symptom.contains(_searchQuery) ||
          shortLabel.contains(_searchQuery) ||
          symptoms.contains(_searchQuery);
    }).toList();
  }

  // ==================================================
  // INTERFACE
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final filteredDiagnostics = _filteredDiagnostics;

    final currentDiag = filteredDiagnostics.isNotEmpty
        ? filteredDiagnostics[
            _selectedSymptomIndex.clamp(
              0,
              filteredDiagnostics.length - 1,
            )
          ]
        : null;

    final currentSolution =
        _solutions.isNotEmpty ? _solutions.first : null;

    final steps = currentSolution != null
        ? _solutionList(currentSolution, 'etapes_reparation')
        : <String>[];

    final tools = currentSolution != null
        ? _solutionList(currentSolution, 'outils')
        : <String>[];

    final difficulty = currentSolution != null
        ? _solutionText(
            currentSolution,
            'difficulte',
            'Non précisée',
          )
        : 'Non précisée';

    final time = currentSolution != null
        ? '${currentSolution['duree_minutes'] ?? '--'} min'
        : '--';

    final co2 = currentSolution != null
        ? '${currentSolution['co2_economise_kg'] ?? '--'} kg CO₂e'
        : '--';

    final causeText = _causes.isNotEmpty
        ? _causes
            .map((c) => c['description'] ?? c['nom_cause'] ?? '')
            .where((v) => v.toString().isNotEmpty)
            .join('\n\n')
        : currentSolution != null
            ? _solutionText(
                currentSolution,
                'description',
                'Aucune description disponible.',
              )
            : 'Aucune cause renseignée.';

    return Scaffold(
      backgroundColor: navy,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.transparent),
      ),
      body: Column(
        children: [
          // EN-TÊTE
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.troubleshoot,
                  color: lightGreen,
                  size: 26,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'DIAGNOSTIC & PANNE',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: lightGreen),
                  ),
                  child: const Text(
                    'Assistant Réparateur',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RECHERCHE
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            padding: const EdgeInsets.only(left: 16, right: 6),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      hintText:
                          'Rechercher un symptôme (lent, écran noir, batterie)...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  height: 34,
                  width: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Color.fromRGBO(5, 21, 44, 1),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // SÉLECTEUR DES PANNES
          if (_isLoadingFaults)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          else if (filteredDiagnostics.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: filteredDiagnostics.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = filteredDiagnostics[index];
                  final selected = _selectedSymptomIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSymptomIndex = index;
                      });

                      _loadFaultDetails(item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? green
                            : const Color(0xFF102542),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? lightGreen
                              : Colors.white24,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: selected
                                ? Colors.white
                                : Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item['shortLabel'].toString(),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 10),

          // CONTENU
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
              child: _buildMainContent(
                currentDiag,
                currentSolution,
                causeText,
                steps,
                tools,
                difficulty,
                time,
                co2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // CONTENU PRINCIPAL
  // ==================================================

  Widget _buildMainContent(
    Map<String, dynamic>? currentDiag,
    Map<String, dynamic>? currentSolution,
    String causeText,
    List<String> steps,
    List<String> tools,
    String difficulty,
    String time,
    String co2,
  ) {
    if (_isLoadingFaults) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CAF50),
        ),
      );
    }

    if (_errorMessage != null && _diagnostics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                color: Colors.orange,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Impossible de charger les diagnostics.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadFaults,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentDiag == null) {
      return const Center(
        child: Text(
          'Aucune panne correspondante trouvée.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
      );
    }

    if (_isLoadingDetails) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CAF50),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FICHE DIAGNOSTIC
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: green.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        currentDiag['icon'] as IconData,
                        color: lightGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DIAGNOSTIC IDENTIFIÉ',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentDiag['symptom'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (currentSolution != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        icon: Icons.build_circle,
                        text: 'Difficulté : $difficulty',
                        color: _difficultyColor(difficulty),
                      ),
                      _buildBadge(
                        icon: Icons.timer,
                        text: time,
                        color: Colors.lightBlueAccent,
                      ),
                      _buildBadge(
                        icon: Icons.eco,
                        text: '$co2 économisés',
                        color: lightGreen,
                      ),
                    ],
                  ),

                const SizedBox(height: 12),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),

                const Text(
                  'CAUSE TECHNIQUE PROBABLE :',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  causeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),

                if (tools.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.handyman,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Outils : ${tools.join(', ')}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                const Text(
                  'PROTOCOLE DE RÉPARATION :',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                if (steps.isEmpty)
                  const Text(
                    'Aucune étape de réparation renseignée.',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  ...steps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // SOLUTIONS
          if (_solutions.isEmpty)
            const Text(
              'Aucune solution de réparation enregistrée pour cette panne.',
              style: TextStyle(color: Colors.white70),
            ),

          // PIÈCES
          Row(
            children: [
              const Icon(
                Icons.inventory_2,
                color: Color(0xFF4CAF50),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'PIÈCES COMPATIBLES (${_partGroups.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (_partGroups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucune pièce nécessaire ou annonce correspondante renseignée.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            )
          else
            ..._partGroups.map(
              (group) => _buildPartGroup(group),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==================================================
  // BADGES
  // ==================================================

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // GROUPE DE PIÈCES
  // ==================================================

  Widget _buildPartGroup(Map<String, dynamic> group) {
    final announcements = group['annonces'] as List<dynamic>? ?? [];

    final bool available = announcements.isNotEmpty;

    final name = group['nom']?.toString() ?? 'Pièce nécessaire';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (!available)
          _buildUnavailableCard(name)
        else
          ...announcements.map((item) {
            final announcement =
                Map<String, dynamic>.from(item);

            return _buildAnnouncementCard(announcement);
          }),
      ],
    );
  }

  // ==================================================
  // PIÈCE NON DISPONIBLE
  // ==================================================

  Widget _buildUnavailableCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.memory,
            color: Colors.grey,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Non disponible',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // ANNONCE DISPONIBLE
  // ==================================================

  Widget _buildAnnouncementCard(
    Map<String, dynamic> announcement,
  ) {
    final announcementId = int.tryParse(
      announcement['announcement_id'].toString(),
    );

    final name = announcement['nom_materiel'] ??
        announcement['titre'] ??
        'Pièce sans nom';

    final condition =
        announcement['etat_piece'] ?? 'État non renseigné';

    final location =
        announcement['lieu_retrait'] ?? 'Lieu non renseigné';

    final quantity = announcement['quantite'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Don',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: Color(0xFF2E7D32),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Disponible',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            name.toString(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 15,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  condition.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 15,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Qté : $quantity',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: announcementId == null
                  ? null
                  : () {
                      final item = {
                        ...announcement,
                        'id': announcementId,
                        'announcement_id': announcementId,
                        'name': name.toString(),
                        'type': 'Don',
                        'category': 1,
                        'subType': name.toString(),
                        'condition': condition.toString(),
                        'partCondition': condition.toString(),
                        'location': location.toString(),
                        'image': announcement['photo'],
                        'icon': Icons.memory,
                      };

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailProduitPage(item: item),
                        ),
                      );
                    },
              icon: const Icon(Icons.build, size: 15),
              label: const Text(
                'Obtenir la pièce',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
