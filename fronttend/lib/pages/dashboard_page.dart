
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await _authService.getEnvironmentalDashboard();

      if (!mounted) return;

      setState(() {
        _dashboardData = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _formatNumber(dynamic value, {int decimals = 2}) {
    if (value == null) return '0';

    final number = (value as num).toDouble();

    return number.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  String _getValue(String key, {String fallback = '—'}) {
    if (_isLoading) return '...';
    if (_dashboardData == null) return fallback;

    return _dashboardData![key]?.toString() ?? fallback;
  }

  List<Map<String, dynamic>> get _components {
    final data = _dashboardData?['most_reused_components'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .take(3)
          .toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 380;

    final double co2Tonnes =
        (_dashboardData?['co2_saved_tonnes'] as num?)?.toDouble() ?? 0;

    final String co2Text = _isLoading
        ? '...'
        : _dashboardData == null
            ? '—'
            : '${_formatNumber(co2Tonnes, decimals: 3)} Tonnes CO₂e';

    final String kilometres = _isLoading
        ? '...'
        : _dashboardData == null
            ? '—'
            : _formatNumber(co2Tonnes * 4583.33, decimals: 0);

    final double? averageScore =
        (_dashboardData?['average_repairability_score'] as num?)
            ?.toDouble();

    final String scoreText = _isLoading
        ? '...'
        : _dashboardData == null
            ? '—'
            : averageScore == null
                ? '—'
                : '${_formatNumber(averageScore, decimals: 1)}/10';

    final List<Map<String, dynamic>> componentList = _components;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(5, 21, 44, 1),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0.0),
        child: AppBar(backgroundColor: Colors.transparent),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12.0 : 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.eco,
                              color: const Color(0xFF4CAF50),
                              size: isSmallScreen ? 24 : 28,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'BILAN & IMPACT',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: isSmallScreen ? 17 : 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF4CAF50)),
                        ),
                        child: const Text(
                          'Données ADEME',
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
              ),
            ),

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
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CARTE CO2
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2E7D32),
                                  Color(0xFF1B5E20)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Expanded(
                                      child: Text(
                                        'EMPREINTE CARBONE ÉVITÉE',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.cloud_done,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  co2Text,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 24 : 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.directions_car,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Équivaut à $kilometres km en voiture thermique',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // LES 3 KPI
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  icon: Icons.laptop_mac,
                                  value: _getValue('equipment_saved'),
                                  label: 'PC Sauvés',
                                  color: const Color(0xFF4CAF50),
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 10),
                              Expanded(
                                child: _buildKpiCard(
                                  icon: Icons.delete_sweep,
                                  value:
                                      '${_getValue('deee_avoided_kg')} kg',
                                  label: 'DEEE Évités',
                                  color: Colors.amber,
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 10),
                              Expanded(
                                child: _buildKpiCard(
                                  icon: Icons.build_circle,
                                  value: scoreText,
                                  label: 'Score Moyen',
                                  color: Colors.lightBlueAccent,
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'COMPOSANTS LES PLUS RÉEMPLOYÉS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              children: componentList.isEmpty
                                  ? [
                                      _buildProgressRow(
                                        _isLoading
                                            ? 'Chargement...'
                                            : 'Aucun composant réemployé',
                                        0,
                                        '0 unité',
                                      ),
                                    ]
                                  : [
                                      for (int i = 0;
                                          i < componentList.length;
                                          i++) ...[
                                        _buildProgressRow(
                                          componentList[i]['name']?.toString() ??
                                              'Autres composants',
                                          ((componentList[i]['percentage']
                                                      as num?)
                                                  ?.toDouble() ??
                                              0) /
                                              100,
                                          '${_formatNumber(componentList[i]['percentage'], decimals: 0)}% (${componentList[i]['count'] ?? 0} unités)',
                                        ),
                                        if (i != componentList.length - 1)
                                          const SizedBox(height: 12),
                                      ],
                                    ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'SOBRIÉTÉ NUMÉRIQUE DE L\'APPLICATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ECOINDEX : CONSERVÉ COMME DANS TON DESIGN INITIAL
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: isSmallScreen ? 42 : 48,
                                  width: isSmallScreen ? 42 : 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2E7D32),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'A',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 10 : 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Score EcoIndex : 86/100',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Thème sombre OLED • Poids vue < 380 Ko • Zéro script tiers énergivore',
                                        style: TextStyle(
                                          color: Color.fromARGB(183, 0, 0, 0),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Impossible de charger les données. Vérifie que le serveur est démarré et que la route /environmental/dashboard fonctionne.',
                              style: TextStyle(
                                color: Colors.orange.shade200,
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: _loadDashboard,
                              child: const Text(
                                'Réessayer',
                                style: TextStyle(color: Color(0xFF4CAF50)),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),
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

  Widget _buildKpiCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 10 : 12,
        horizontal: isSmallScreen ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14.5 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isSmallScreen ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    String title,
    double percent,
    String trailingText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              trailingText,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF4CAF50),
            ),
          ),
        ),
      ],
    );
  }
}
