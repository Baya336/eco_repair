
import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'profil_page.dart';
import '../services/auth_service.dart';
import 'user_session.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  String _selectedRole = 'Étudiant / Particulier';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validerInscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Créer le compte
      final user = await _authService.register(
        nom: _nomController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        adresse: _adresseController.text.trim(),
        role: _selectedRole,
      );

      // 2. Connecter automatiquement l'utilisateur
      final loginData = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 3. Vérifier que le token a bien été récupéré
      if (AuthService.accessToken == null ||
          AuthService.accessToken!.isEmpty) {
        throw Exception('Impossible de récupérer le token de connexion.');
      }

      if (!mounted) return;

      // 4. Enregistrer les informations de l'utilisateur
      globalUserName = user['nom'];
      globalUserEmail = user['email'];
      globalUserAddress = user['adresse'] ?? '';
      globalUserRole = _selectedRole;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content: Text(
            'Compte créé et connexion réussie ! Bienvenue sur EcoRepair.',
          ),
        ),
      );

      // 5. Accéder à l'application
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'INSCRIPTION',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
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
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 22.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 550),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Créer un compte EcoRepair',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Accède aux dons, prêts de matériel et pièces détachées.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildTextField(
                            controller: _nomController,
                            label: 'Nom et Prénom',
                            icon: Icons.person_outline,
                            validator: (val) =>
                                val == null || val.isEmpty
                                    ? 'Champ obligatoire'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: _emailController,
                            label: 'Adresse e-mail (ex: nom@univ-evry.fr)',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) =>
                                val == null || !val.contains('@')
                                    ? 'Entrez une adresse e-mail valide'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: _adresseController,
                            label: 'Adresse (Rue, Code postal, Ville)',
                            icon: Icons.location_on_outlined,
                            keyboardType: TextInputType.streetAddress,
                            validator: (val) =>
                                val == null || val.isEmpty
                                    ? 'Veuillez entrer votre adresse'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          _buildDropdown(
                            label: 'PROFIL',
                            icon: Icons.badge_outlined,
                            value: _selectedRole,
                            items: const [
                              'Étudiant / Particulier',
                              'Réparateur / FabLab',
                              'Donateur / Service IT',
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRole = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: _passwordController,
                            label: 'Mot de passe (6 caractères min.)',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.length < 6
                                    ? 'Minimum 6 caractères'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirmer le mot de passe',
                            icon: Icons.lock_reset,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                            validator: (val) =>
                                val != _passwordController.text
                                    ? 'Les mots de passe ne correspondent pas'
                                    : null,
                          ),
                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : _validerInscription,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'CRÉER MON COMPTE',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Déjà inscrit ? Se connecter',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
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
        suffixIcon: suffixIcon,
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
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
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
              value: value,
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
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: const Color(0xFF4CAF50),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
