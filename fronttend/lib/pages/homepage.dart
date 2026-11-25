import 'package:flutter/material.dart';
import 'detail_produit_page.dart';
import 'profil_page.dart';
import 'user_session.dart';
import '../services/auth_service.dart';

List globalCartItems = [];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'Appareils';
  String _searchQuery = '';

  // Annonces statiques : elles restent affichées
  
    
 
  

  // Annonces récupérées depuis PostgreSQL
  List<Map<String, dynamic>> _realItems = [];
  final Set<int> _addingAnnouncementIds = {};

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final announcements = await AuthService().getAnnouncements();

      final List<Map<String, dynamic>> loadedItems =
          announcements.map<Map<String, dynamic>>((announcement) {
        final String typeMateriel =
            (announcement['type_materiel'] ?? 'equipement').toString();

        final String typeOffre =
            (announcement['type_offre'] ?? 'don').toString();

        final dynamic scoreValue =
            announcement['indice_reparabilite'];

        final double? score = scoreValue == null
            ? null
            : double.tryParse(scoreValue.toString());

        final dynamic co2Value =
            announcement['co2_economise_kg'];

        final double? co2 = co2Value == null
            ? null
            : double.tryParse(co2Value.toString());

        final String? co2Text = co2 == null
            ? null
            : '${co2 == co2.roundToDouble() ? co2.toInt() : co2} kg CO₂';

        final String sousType =
            (announcement['sous_type'] ?? '').toString();

        final String nom =
            (announcement['nom_materiel'] ??
                    announcement['titre'] ??
                    'Matériel')
                .toString();

        return {
          'id': announcement['id'],
          'userId': announcement['user_id'],
          'name': nom,
          'category': typeMateriel == 'piece'
              ? 'Pièces détachées'
              : 'Appareils',
          'type': typeOffre == 'pret' ? 'Prêt' : 'Don',
          'repairScore': score,
          'co2Saved': co2Text,
          'location':
              announcement['lieu_retrait'] ?? 'Non renseigné',
          'image': announcement['photo'],
          'icon': _getItemIcon(sousType, nom),
          'subType': sousType,
          'description': announcement['description'] ?? '',
          'partCondition': announcement['etat_piece'],
          'condition': announcement['etat_objet'],
          'quantity': announcement['quantite'] ?? 1,
          'status': announcement['statut'],
          'weight': announcement['poids_kg'],
          'isStatic': false,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _realItems = loadedItems;
      });
    } catch (e) {
      // En cas d'erreur réseau, les annonces statiques restent affichées.
      debugPrint('Erreur chargement des annonces : $e');
    }
  }

  IconData _getItemIcon(String sousType, String nom) {
    final String text = '$sousType $nom'.toLowerCase();

    if (text.contains('ram') || text.contains('mémoire')) {
      return Icons.memory;
    }
    if (text.contains('ssd') ||
        text.contains('disque') ||
        text.contains('stockage')) {
      return Icons.storage;
    }
    if (text.contains('écran') || text.contains('moniteur')) {
      return Icons.desktop_windows;
    }
    if (text.contains('batterie') || text.contains('chargeur')) {
      return Icons.battery_charging_full;
    }
    if (text.contains('pc') ||
        text.contains('ordinateur') ||
        text.contains('portable')) {
      return Icons.laptop;
    }

    return Icons.devices;
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return const Color(0xFF2E7D32);
    if (score >= 6.0) return Colors.orange;
    return Colors.redAccent;
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
  final int? announcementId =
      int.tryParse(item['id']?.toString() ?? '');

  // Les annonces statiques n'existent pas dans PostgreSQL.
  if (announcementId == null || item['isStatic'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cette annonce de démonstration ne peut pas être ajoutée au panier.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Évite les doubles clics pendant l'enregistrement.
  if (_addingAnnouncementIds.contains(announcementId)) return;

  setState(() {
    _addingAnnouncementIds.add(announcementId);
  });

  try {
    await AuthService().addToCart(announcementId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        content: Text(
          '${item['name']} (${item['type']}) ajouté au panier !',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        content: Text(
          'Impossible d’ajouter cette annonce : ${e.toString()}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _addingAnnouncementIds.remove(announcementId);
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 380;

    // Afficher uniquement les annonces récupérées depuis PostgreSQL.
final List<Map<String, dynamic>> allItems = [
  ..._realItems,
];

    final filteredItems = allItems.where((item) {
      final matchesCat = item['category'] == _selectedCategory;

      final matchesSearch = item['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      return matchesCat && matchesSearch;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          // EN-TÊTE RESPONSIVE
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 14.0 : 20.0,
              vertical: 10.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.eco,
                            color: Color(0xFF4CAF50),
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'ECOREPAIR',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 20 : 23,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilPage(),
                          ),
                        );
                        setState(() {});
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF2E7D32),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            globalUserName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // BARRE DE RECHERCHE
                Container(
                  height: 46,
                  padding: const EdgeInsets.only(left: 16, right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'Rechercher un PC, RAM, écran, batterie...',
                            hintStyle: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // BOUTONS CATÉGORIES
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryButton(
                        title: 'Appareils',
                        subtitle: 'PC, Écrans, téléphones',
                        icon: Icons.devices,
                        isSelected: _selectedCategory == 'Appareils',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCategoryButton(
                        title: 'Pièces détachées',
                        subtitle: 'RAM, SSD, Batteries',
                        icon: Icons.memory,
                        isSelected:
                            _selectedCategory == 'Pièces détachées',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CONTENEUR BLEU ET GRILLE
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0F2647),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 18,
                  16,
                  isSmallScreen ? 12 : 18,
                  0,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedCategory == 'Appareils'
                                ? 'APPAREILS DISPONIBLES (DON / PRÊT)'
                                : 'PIÈCES DÉTACHÉES DISPONIBLES',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 11.5 : 13,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${filteredItems.length} résultats',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: filteredItems.length,
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio:
                                  constraints.maxWidth < 360 ? 0.68 : 0.74,
                            ),
                            itemBuilder: (context, index) {
                              return _buildCard(filteredItems[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32)
              : const Color(0xFF0F2647),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : Colors.white24,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final dynamic scoreValue = item['repairScore'];

    final double? score = scoreValue == null
        ? null
        : (scoreValue as num).toDouble();

    final Color scoreColor =
        score == null ? Colors.grey : _getScoreColor(score);

    final bool isDon = item['type'] == 'Don';

    final String? imagePath = item['image']?.toString();

    final IconData itemIcon =
        (item['icon'] as IconData?) ?? Icons.devices;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailProduitPage(item: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BADGES HAUT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDon
                        ? const Color(0xFF2E7D32)
                        : Colors.indigo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['type'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),

                if (score != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: scoreColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.build,
                            size: 10,
                            color: scoreColor,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '$score/10',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // IMAGE
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: imagePath == null || imagePath.isEmpty
                    ? Icon(
                        itemIcon,
                        size: 44,
                        color: const Color(0xFF2E7D32),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imagePath.startsWith('http://') ||
                                imagePath.startsWith('https://')
                            ? Image.network(
                                imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  itemIcon,
                                  size: 44,
                                  color: const Color(0xFF2E7D32),
                                ),
                              )
                            : Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  itemIcon,
                                  size: 44,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // TITRE
            Text(
              item['name'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 3),

            // CO2
            Row(
              children: [
                const Icon(
                  Icons.eco,
                  size: 13,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item['co2Saved'] == null
                        ? 'CO₂ non renseigné'
                        : '-${item['co2Saved']}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // LOCALISATION ET PANIER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item['location'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
  onTap: () => _addToCart(item),
  child: Container(
    width: 28,
    height: 28,
    decoration: const BoxDecoration(
      color: Color(0xFF2E7D32),
      shape: BoxShape.circle,
    ),
    child: _addingAnnouncementIds.contains(
      int.tryParse(item['id']?.toString() ?? ''),
    )
        ? const Padding(
            padding: EdgeInsets.all(7),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          )
        : const Icon(
            Icons.add,
            color: Colors.white,
            size: 18,
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