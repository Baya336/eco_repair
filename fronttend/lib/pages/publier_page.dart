
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../services/auth_service.dart';

class PublierPage extends StatefulWidget {
  const PublierPage({super.key});

  @override
  State<PublierPage> createState() => _PublierPageState();
}

class _PublierPageState extends State<PublierPage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(text: 'Campus Évry');
  final TextEditingController _specsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  // États du formulaire
  String _offerType = 'Don';
  int _selectedCategory = 0;
  String _subType = 'PC Portable';
  double _repairScore = 8.4;
  String _partCondition = 'Testée 100% fonctionnelle';

  // PHOTO : sélection et compression
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedPhoto;

  bool _isSubmitting = false;

  // Barème CO2
  final Map<String, String> _co2BySubType = {
    'PC Portable': '156 kg',
    'PC Fixe / Tour': '220 kg',
    'Écran / Moniteur': '85 kg',
    'Barrette de RAM': '14 kg',
    'Disque SSD / HDD': '28 kg',
    'Batterie / Chargeur': '18 kg',
    'Autre composant': '15 kg',
  };

  List<String> get _currentSubTypes => _selectedCategory == 0
      ? ['PC Portable', 'PC Fixe / Tour', 'Écran / Moniteur']
      : [
          'Barrette de RAM',
          'Disque SSD / HDD',
          'Batterie / Chargeur',
          'Autre composant'
        ];

  String get _calculatedCo2 => _co2BySubType[_subType] ?? '50 kg';

  Color _getScoreColor(double score) {
    if (score >= 8.0) return const Color(0xFF4CAF50);
    if (score >= 6.0) return const Color(0xFFFFB300);
    return const Color(0xFFE53935);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _specsController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // =====================================================
  // PHOTO : CHOISIR UNE PHOTO (GALERIE OU APPAREIL PHOTO)
  // =====================================================

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2647),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF4CAF50),
                ),
                title: const Text(
                  'Choisir dans la galerie',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF4CAF50),
                ),
                title: const Text(
                  'Prendre une photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sélectionner une photo
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (photo == null || !mounted) return;

      setState(() {
        _selectedPhoto = photo;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de sélectionner la photo : $e'),
        ),
      );
    }
  }

  // Compresser la photo à moins de 100 Ko si possible
  Future<File> _compressPhoto(XFile photo) async {
    final String targetPath =
        '${Directory.systemTemp.path}/announcement_${DateTime.now().microsecondsSinceEpoch}.jpg';

    int quality = 80;
    int dimension = 1000;

    while (quality >= 30) {
      final compressed =
          await FlutterImageCompress.compressAndGetFile(
        photo.path,
        targetPath,
        quality: quality,
        minWidth: dimension,
        minHeight: dimension,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        throw Exception('La compression de la photo a échoué.');
      }

      final File result = File(compressed.path);
      final int fileSize = await result.length();

      if (fileSize <= 100 * 1024) {
        return result;
      }

      if (quality > 40) {
        quality -= 10;
      } else {
        dimension = (dimension * 0.75).round();
        quality = 70;
      }

      if (dimension < 300) {
        break;
      }
    }

    throw Exception(
      'La photo reste supérieure à 100 Ko après compression. '
      'Veuillez choisir une image moins volumineuse.',
    );
  }

  // Envoyer la photo au backend
  Future<String> _uploadPhoto(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${AuthService.baseUrl}/announcements/upload-photo',
      ),
    );

    request.headers['Authorization'] =
        'Bearer ${AuthService.accessToken}';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Erreur lors de l’envoi de la photo : ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data['photo'] == null) {
      throw Exception(
        'Le serveur n’a pas retourné le chemin de la photo.',
      );
    }

    return data['photo'].toString();
  }

  // PUBLICATION DE L'ANNONCE
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (AuthService.accessToken == null ||
        AuthService.accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? photoPath;

      // 1. Compresser et envoyer la photo si elle existe
      if (_selectedPhoto != null) {
        final File compressedPhoto =
            await _compressPhoto(_selectedPhoto!);

        try {
          photoPath = await _uploadPhoto(compressedPhoto);
        } finally {
          if (await compressedPhoto.exists()) {
            await compressedPhoto.delete();
          }
        }
      }

      // 2. Préparer les données de l'annonce
      final Map<String, dynamic> newAnnouncement = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'subType': _subType,
        'type': _offerType,
        'repairScore':
            _selectedCategory == 0 ? _repairScore : null,
        'partCondition':
            _selectedCategory == 1 ? _partCondition : null,
        'location': _locationController.text.trim(),
        'description': _specsController.text.trim(),
        'image': photoPath,
        'poids_kg': double.parse(
          _weightController.text.trim().replaceAll(',', '.'),
        ),
        'quantite': int.parse(_quantityController.text.trim()),
      };

      // 3. Envoyer l'annonce
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/announcements/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
        body: jsonEncode(newAnnouncement),
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _nameController.clear();
        _specsController.clear();
        _weightController.clear();
        _quantityController.text = '1';

        setState(() {
          _selectedPhoto = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce publiée avec succès !'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      } else {
        String errorMessage = response.body;

        try {
          final decoded = jsonDecode(response.body);
          errorMessage =
              decoded['detail']?.toString() ?? errorMessage;
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur ${response.statusCode} : $errorMessage',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isSmallScreen = screenWidth < 380;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(5, 21, 44, 1),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0.0),
        child: AppBar(backgroundColor: Colors.transparent),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. EN-TÊTE FIXE RESPONSIVE
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12.0 : 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        color: const Color(0xFF4CAF50),
                        size: isSmallScreen ? 23 : 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PROPOSER MATÉRIEL',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontSize: isSmallScreen ? 15.5 : 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32)
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        child: Text(
                          '- $_calculatedCo2',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. CONTENEUR BLEU ET FORMULAIRE
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
                  padding: EdgeInsets.all(
                    isSmallScreen ? 14.0 : 18.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 700,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // CHOIX 1 : DON OU PRÊT
                            _buildSectionTitle(
                              '1. TYPE D\'OFFRE SOLIDAIRE',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildChoiceTile(
                                    title: 'Don définitif',
                                    subtitle: 'Cession gratuite',
                                    icon: Icons.card_giftcard,
                                    isSelected:
                                        _offerType == 'Don',
                                    activeColor:
                                        const Color(0xFF2E7D32),
                                    isSmallScreen: isSmallScreen,
                                    onTap: () => setState(
                                      () => _offerType = 'Don',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: isSmallScreen ? 8 : 12,
                                ),
                                Expanded(
                                  child: _buildChoiceTile(
                                    title: 'Prêt temporaire',
                                    subtitle: 'Dépannage / Études',
                                    icon: Icons.handshake,
                                    isSelected:
                                        _offerType == 'Prêt',
                                    activeColor: Colors.indigo,
                                    isSmallScreen: isSmallScreen,
                                    onTap: () {
                                      if (_selectedCategory == 1) {
                                        return;
                                      }
                                      setState(
                                        () => _offerType = 'Prêt',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // CHOIX 2 : CATÉGORIE
                            _buildSectionTitle(
                              '2. CATÉGORIE DE MATÉRIEL',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildChoiceTile(
                                    title: 'Appareil complet',
                                    subtitle: 'PC, Écran...',
                                    icon: Icons.laptop_mac,
                                    isSelected:
                                        _selectedCategory == 0,
                                    activeColor:
                                        const Color(0xFF2E7D32),
                                    isSmallScreen: isSmallScreen,
                                    onTap: () => setState(() {
                                      _selectedCategory = 0;
                                      _subType = 'PC Portable';
                                    }),
                                  ),
                                ),
                                SizedBox(
                                  width: isSmallScreen ? 8 : 12,
                                ),
                                Expanded(
                                  child: _buildChoiceTile(
                                    title: 'Pièce détachée',
                                    subtitle: 'RAM, SSD, Batterie...',
                                    icon: Icons.memory,
                                    isSelected:
                                        _selectedCategory == 1,
                                    activeColor:
                                        const Color(0xFF2E7D32),
                                    isSmallScreen: isSmallScreen,
                                    onTap: () => setState(() {
                                      _selectedCategory = 1;
                                      _subType = 'Barrette de RAM';
                                      _offerType = 'Don';
                                    }),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // SOUS-CATÉGORIE ET CO2
                            _buildSectionTitle(
                              '3. SOUS-TYPE & IMPACT CARBONE ESTIMÉ',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _currentSubTypes.map((type) {
                                final bool isSelected =
                                    _subType == type;
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _subType = type,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          isSmallScreen ? 11 : 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2E7D32)
                                          : Colors.white
                                              .withOpacity(0.06),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF4CAF50)
                                            : Colors.white24,
                                      ),
                                    ),
                                    child: Text(
                                      '$type (-${_co2BySubType[type]})',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize:
                                            isSmallScreen ? 11.5 : 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 18),

                            // INFORMATIONS DU MATÉRIEL
                            _buildSectionTitle(
                              '4. INFORMATIONS DU MATÉRIEL',
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameController,
                              label: _selectedCategory == 0
                                  ? 'Modèle exact (ex: Dell Latitude 5420 / ThinkPad T480)'
                                  : 'Référence de la pièce (ex: RAM Crucial 8Go DDR4 2666MHz)',
                              icon: Icons.devices,
                              validator: (val) =>
                                  val == null || val.isEmpty
                                      ? 'Veuillez indiquer le nom du matériel'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _locationController,
                              label:
                                  'Lieu de remise (ex: Campus Évry - Bâtiment IBGBI)',
                              icon: Icons.location_on,
                              validator: (val) =>
                                  val == null || val.isEmpty
                                      ? 'Veuillez préciser le lieu'
                                      : null,
                            ),

                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: _weightController,
                              label: 'Poids du matériel (kg)',
                              icon: Icons.scale,
                              validator: (val) {
                                final weight = double.tryParse(
                                  (val ?? '').replaceAll(',', '.'),
                                );
                                if (weight == null || weight <= 0) {
                                  return 'Veuillez saisir un poids supérieur à 0';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: _quantityController,
                              label: 'Quantité disponible',
                              icon: Icons.inventory_2,
                              validator: (val) {
                                final quantity =
                                    int.tryParse(val ?? '');
                                if (quantity == null || quantity < 1) {
                                  return 'La quantité doit être au minimum de 1';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // INDICE DE RÉPARABILITÉ OU ÉTAT DE LA PIÈCE
                            if (_selectedCategory == 0) ...[
                              _buildSectionTitle(
                                '5. INDICE DE RÉPARABILITÉ OFFICIEL',
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(
                                  isSmallScreen ? 12 : 14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.06),
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white12,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Note sur 10 (facilité de démontage) :',
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize:
                                                  isSmallScreen ? 12 : 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getScoreColor(
                                              _repairScore,
                                            ).withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _getScoreColor(
                                                _repairScore,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.build_circle,
                                                color: _getScoreColor(
                                                  _repairScore,
                                                ),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_repairScore.toStringAsFixed(1)} / 10',
                                                style: TextStyle(
                                                  color: _getScoreColor(
                                                    _repairScore,
                                                  ),
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize:
                                                      isSmallScreen
                                                          ? 13.5
                                                          : 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: _repairScore,
                                      min: 1.0,
                                      max: 10.0,
                                      divisions: 90,
                                      activeColor: _getScoreColor(
                                        _repairScore,
                                      ),
                                      inactiveColor: Colors.white24,
                                      onChanged: (val) => setState(
                                        () => _repairScore = val,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              _buildSectionTitle(
                                '5. ÉTAT TECHNIQUE DE LA PIÈCE DÉTACHÉE',
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.06),
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white12,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _partCondition,
                                    dropdownColor:
                                        const Color(0xFF0F2647),
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    items: [
                                      'Testée 100% fonctionnelle',
                                      'Neuve (Sous blister)',
                                      'Fonctionnelle (Usure normale)',
                                      'À tester par un réparateur',
                                    ].map((String condition) {
                                      return DropdownMenuItem<String>(
                                        value: condition,
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.verified,
                                              color: Color(0xFF4CAF50),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                condition,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                          () => _partCondition = val,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),

                            // DÉTAILS TECHNIQUES
                            _buildSectionTitle(
                              '6. DÉTAILS TECHNIQUES & COMPATIBILITÉ',
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _specsController,
                              label: _selectedCategory == 0
                                  ? 'Ex: Core i5, 16Go RAM, sans chargeur, batterie à 80%...'
                                  : 'Ex: Format SO-DIMM DDR4, compatible ThinkPad T480 / Dell Latitude...',
                              icon: Icons.description,
                              maxLines: 2,
                            ),

                            const SizedBox(height: 18),

                            // PHOTO DU MATÉRIEL
                            _buildSectionTitle(
                              '7. PHOTO DU MATÉRIEL (COMPRESSÉE < 100 Ko)',
                            ),
                            const SizedBox(height: 8),

                            GestureDetector(
                              onTap: _showPhotoOptions,
                              child: Container(
                                height: (screenSize.height * 0.14)
                                    .clamp(100.0, 140.0),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.06),
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _selectedPhoto != null
                                        ? const Color(0xFF4CAF50)
                                        : Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(17),
                                  child: _selectedPhoto != null
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.file(
                                              File(_selectedPhoto!.path),
                                              fit: BoxFit.cover,
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedPhoto = null;
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                ),
                                                style:
                                                    IconButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red
                                                          .withOpacity(0.85),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.65),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(10),
                                                ),
                                                child: const Text(
                                                  'Photo sélectionnée ✓',
                                                  textAlign:
                                                      TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                color: Color(0xFF4CAF50),
                                                size: 28,
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'Appuyer pour joindre une photo du matériel',
                                                textAlign:
                                                    TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              Text(
                                                'Galerie ou appareil photo',
                                                textAlign:
                                                    TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // BOUTON DE PUBLICATION
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18),
                                  ),
                                  elevation: 4,
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : _submitForm,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.publish,
                                        size: 22,
                                      ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'PUBLIER LE ${_offerType.toUpperCase()} (-$_calculatedCo2 CO₂)',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
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
            ),
          ],
        ),
      ),
    );
  }

  // TITRE DE SECTION
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  // BOUTON DE CHOIX VISUEL
  Widget _buildChoiceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required bool isSmallScreen,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.25)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : Colors.white54,
              size: isSmallScreen ? 22 : 26,
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12.5 : 13.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isSmallScreen ? 10.5 : 11,
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

  // CHAMP DE SAISIE STYLISÉ
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white60,
          fontSize: 13,
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
          borderSide: const BorderSide(
            color: Colors.white12,
          ),
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
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}
