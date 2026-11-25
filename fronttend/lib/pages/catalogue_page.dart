import 'package:flutter/material.dart';
import '../services/device_service.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  final TextEditingController _searchController = TextEditingController();
  final DeviceService _deviceService = DeviceService();
  static const String _imageBaseUrl = 'http://10.0.2.2:8000/';

  List<Map<String, dynamic>> _catalogDevices = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  
Future<void> _loadDevices() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final devices = await _deviceService.getDevices();
    debugPrint('APPAREILS API : $devices');

    setState(() {
      _catalogDevices = devices.map((device) {
        return _convertDevice(
          Map<String, dynamic>.from(device),
        );
      }).toList();
    });
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}



Map<String, dynamic> _convertDevice(Map<String, dynamic> data) {
  return {
    'id': data['id'],
    'name': data['nom'] ?? 'Appareil sans nom',
    'category': 'Catégorie ${data['category_id']}',
    'releaseDate': data['date_sortie'] ?? 'Date inconnue',
    'repairScore': double.tryParse(
      data['indice_reparabilite']?.toString() ?? '',
    ) ?? 0.0,
    'image': data['photo'],
    'icon': Icons.devices,
    'description': data['description'] ?? 'Aucune description disponible',
    'manualTitle': data['manual_titre'] ?? 'Aucun manuel disponible',
    'manualPdf': data['manual_pdf'],
    'tools': data['outils'] ?? 'Outils non renseignés',
    'steps': List<String>.from(data['etapes_reparation'] ?? []),
  };
}

  

  @override
void initState() {
  super.initState();

  _loadDevices();

  _searchController.addListener(() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return const Color(0xFF2E7D32);
    if (score >= 6.0) return const Color(0xFFFF8F00);
    return const Color(0xFFC62828);
  }

  // Ouvre la nouvelle page de détail complète quand on clique sur un appareil
  void _openDetailPage(BuildContext context, Map<String, dynamic> device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FicheMaterielDetailPage(device: device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 380;

    final bool isSearching = _searchQuery.isNotEmpty;

    final filteredDevices = !isSearching
        ? []
        : _catalogDevices.where((device) {
            return device['name']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery) ||
                device['description']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(5, 21, 44, 1),
      body: SafeArea(
        child: Column(
          children: [
            // 1. EN-TÊTE RESPONSIVE
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12.0 : 16.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              color: const Color(0xFF4CAF50),
                              size: isSmallScreen ? 24 : 28,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'FICHES MATÉRIEL',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
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
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_catalogDevices.length} modèles',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. BARRE DE RECHERCHE RESPONSIVE
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12.0 : 16.0,
                    vertical: 6.0,
                  ),
                  padding: const EdgeInsets.only(left: 16.0, right: 6.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText:
                                'Rechercher un modèle, processeur, manuel...',
                            hintStyle: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
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
              ),
            ),

            const SizedBox(height: 10),

            // 3. CONTENEUR BLEU & LISTE ADAPTATIVE
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F2647),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: isSmallScreen ? 12 : 16,
                  right: isSmallScreen ? 12 : 16,
                  top: 18,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            'RÉFÉRENTIEL TECHNIQUE & MANUELS',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              fontSize: isSmallScreen ? 12.5 : 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Expanded(
                          child: !isSearching
                              ? const Center(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                    ),
                                    child: Text(
                                      '🔍 Tape un nom de matériel dans la barre de recherche ci-dessus pour afficher sa fiche technique et ses guides de réparation.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                              : filteredDevices.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Aucun matériel trouvé pour cette recherche.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      itemCount: filteredDevices.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 14),
                                      itemBuilder: (context, index) {
                                        return _buildDeviceReferenceCard(
                                          context,
                                          filteredDevices[index],
                                          isSmallScreen,
                                        );
                                      },
                                    ),
                        ),
                      ],
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

  // Carte de fiche technique responsive (cliquable)
  Widget _buildDeviceReferenceCard(
    BuildContext context,
    Map<String, dynamic> device,
    bool isSmallScreen,
  ) {
    final double score = (device['repairScore'] as num).toDouble();
    final Color scoreColor = _getScoreColor(score);
    final bool hasImage = device['image'] != null;
    final double thumbSize = isSmallScreen ? 70.0 : 85.0;

    return GestureDetector(
      onTap: () => _openDetailPage(context, device),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Miniature adaptative
                Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
  color: const Color(0xFFE8F5E9),
  borderRadius: BorderRadius.circular(16),
),
child: hasImage
    ? ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          Uri.parse(
            _imageBaseUrl,
          ).resolve(device['image'].toString()).toString(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.devices,
              size: 44,
              color: Color(0xFF2E7D32),
            );
          },
        ),
      )
    : Icon(
        device['icon'] as IconData,
        size: isSmallScreen ? 36 : 44,
        color: const Color(0xFF2E7D32),
      ),
                ),
                const SizedBox(width: 10),

                // Infos principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2647).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          device['category'] as String,
                          style: const TextStyle(
                            color: Color(0xFF0F2647),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        device['name'] as String,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              device['releaseDate'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Badge Score
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scoreColor, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.build_circle,
                        color: scoreColor,
                        size: isSmallScreen ? 18 : 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$score/10',
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12.5 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 10),
            Text(
              device['description'] as String,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // Bas de carte adaptatif (Outils + Bouton Manuel)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.handyman,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          device['tools'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 10 : 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openDetailPage(context, device),
                  icon: const Icon(Icons.menu_book, size: 15),
                  label: Text(
                    'Manuel & Guide',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11.5 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NOUVELLE PAGE DE DÉTAIL DE L'APPAREIL & MANUEL (100% RESPONSIVE)
// ============================================================================
class FicheMaterielDetailPage extends StatelessWidget {
  final Map<String, dynamic> device;

  const FicheMaterielDetailPage({super.key, required this.device});

  Color _getScoreColor(double score) {
    if (score >= 8.0) return const Color(0xFF2E7D32);
    if (score >= 6.0) return const Color(0xFFFF8F00);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 380;

    final double score = (device['repairScore'] as num).toDouble();
    final Color scoreColor = _getScoreColor(score);
    final bool hasImage = device['image'] != null;
    final List<String> steps = List<String>.from(device['steps'] ?? []);

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
          device['name'] as String,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 15.5 : 17.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: double.infinity,
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
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. CARTE DE LA FICHE MATÉRIEL
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F2647)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              device['category'] as String,
                                              style: const TextStyle(
                                                color: Color(0xFF0F2647),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 13,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                device['releaseDate'] as String,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scoreColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: scoreColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.build_circle,
                                            color: scoreColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$score/10',
                                            style: TextStyle(
                                              color: scoreColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Image de l'appareil (Responsive)
                                Container(
  height: (screenSize.height * 0.20).clamp(
    130.0,
    190.0,
  ),
  width: double.infinity,
  decoration: BoxDecoration(
    color: const Color(0xFFE8F5E9),
    borderRadius: BorderRadius.circular(18),
  ),
  child: hasImage
      ? ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            Uri.parse('http://10.0.2.2:8000/')
                .resolve(device['image'].toString())
                .toString(),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                device['icon'] as IconData,
                size: isSmallScreen ? 52 : 64,
                color: const Color(0xFF2E7D32),
              );
            },
          ),
        )
      : Icon(
          device['icon'] as IconData,
          size: isSmallScreen ? 52 : 64,
          color: const Color(0xFF2E7D32),
        ),
),
                                const SizedBox(height: 14),

                                Text(
                                  device['name'] as String,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 17 : 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  device['description'] as String,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Colors.black12),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.handyman,
                                      size: 17,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        device['tools'] as String,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black87,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2. BLOC DU MANUEL & PROCÉDURE (Exactement comme ta pop-up)
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.picture_as_pdf,
                                        color: Color(0xFF4CAF50),
                                        size: 26,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          device['manualTitle'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'PROCÉDURE DE DÉMONTAGE & RÉUTILISATION :',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...steps.map(
                                  (step) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5.0,
                                    ),
                                    child: Text(
                                      step,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              const Color(0xFF2E7D32),
                                          content: Text(
                                            'Téléchargement de "${device['manualTitle']}" lancé...',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.download),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Télécharger le manuel PDF complet',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}