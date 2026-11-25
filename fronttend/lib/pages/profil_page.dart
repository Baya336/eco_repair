import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'user_session.dart';
import '../services/auth_service.dart';


List globalUserRequests = [
  {
    'title': 'PC Dell XPS / Latitude',
    'type': 'Don',
    'date': 'Demande du 12/11/2026',
    'status': 'Prêt à retirer (Salle 04)',
    'statusColor': const Color(0xFF4CAF50),
  },
  {
    'title': 'Lenovo ThinkPad T480 (7 jours)',
    'type': 'Prêt',
    'date': 'Du 13/11/2026 au 20/11/2026',
    'status': 'En attente de validation',
    'statusColor': Colors.orangeAccent,
  },
];

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _adresseController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: globalUserName);
    _emailController = TextEditingController(text: globalUserEmail);
    _adresseController = TextEditingController(text: globalUserAddress);
    _selectedRole = globalUserRole;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  void _sauvegarderInfos() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        globalUserName = _nomController.text.trim();
        globalUserEmail = _emailController.text.trim();
        globalUserAddress = _adresseController.text.trim();
        globalUserRole = _selectedRole;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content: Text('Informations personnelles mises à jour !'),
        ),
      );
    }
  }

  void _seDeconnecter() {
  // Réinitialiser les informations de l'utilisateur
  globalUserName = '';
  globalUserEmail = '';
  globalUserAddress = '';
  globalUserRole = '';

  // Supprimer également le token de connexion
  AuthService.accessToken = null;

  // Réinitialiser la navigation et revenir à la connexion
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const AuthPage(),
    ),
    (route) => false,
  );
}

    

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 380;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(5, 21, 44, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MON ESPACE & SUIVI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 14.0 : 20.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFF2E7D32),
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        globalUserName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$globalUserRole • $globalUserEmail',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. SUIVI DES DEMANDES ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'SUIVI DE MES DEMANDES',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${globalUserRequests.length} en cours',
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: globalUserRequests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final req = globalUserRequests[index];
                            final bool isDon = req['type'] == 'Don';
                            final Color statusColor =
                                (req['statusColor'] as Color?) ??
                                const Color(0xFF4CAF50);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.spaceBetween,
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
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          req['type'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: statusColor,
                                            ),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                req['status'] as String,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: statusColor ==
                                                          Colors.orangeAccent
                                                      ? Colors.deepOrange
                                                      : const Color(0xFF2E7D32),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    req['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    req['date'] as String,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // --- 2. MODIFIER MES INFORMATIONS ---
                        const Text(
                          'MODIFIER MES INFORMATIONS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildField(
                                controller: _nomController,
                                label: 'Nom d\'utilisateur',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                controller: _emailController,
                                label: 'Adresse e-mail',
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                controller: _adresseController,
                                label: 'Adresse postale',
                                icon: Icons.location_on_outlined,
                              ),
                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedRole,
                                    dropdownColor: const Color(0xFF0F2647),
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                    ),
                                    items: const [
                                      'Étudiant / Particulier',
                                      'Réparateur / FabLab',
                                      'Donateur / Service IT',
                                    ].map((String role) {
                                      return DropdownMenuItem<String>(
                                        value: role,
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.badge_outlined,
                                              color: Color(0xFF4CAF50),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                role,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedRole = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _sauvegarderInfos,
                                  icon: const Icon(Icons.save_outlined, size: 19),
                                  label: const Text(
                                    'ENREGISTRER MES INFOS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 12),

                        // --- 3. SE DÉCONNECTER ---
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _seDeconnecter,
                            icon: const Icon(Icons.logout, size: 19),
                            label: const Text(
                              'SE DÉCONNECTER',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
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
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12.5),
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
      ),
    );
  }
}