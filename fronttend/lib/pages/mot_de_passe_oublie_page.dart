
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MotDePasseOubliePage extends StatefulWidget {
  const MotDePasseOubliePage({super.key});

  @override
  State<MotDePasseOubliePage> createState() =>
      _MotDePasseOubliePageState();
}

class _MotDePasseOubliePageState
    extends State<MotDePasseOubliePage> {
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : const Color(0xFF2E7D32),
      ),
    );
  }

  // ÉTAPE 1 : ENVOYER LE CODE

  Future<void> _sendCode() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _showMessage(
        'Veuillez saisir une adresse e-mail valide.',
        error: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.forgotPassword(email: email);

      if (!mounted) return;

      setState(() => _step = 2);

      _showMessage(
        'Si cette adresse existe, un code a été envoyé par e-mail.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ÉTAPE 2 : RÉINITIALISER LE MOT DE PASSE

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      _showMessage(
        'Le code doit contenir exactement 6 chiffres.',
        error: true,
      );
      return;
    }

    if (password.length < 8) {
      _showMessage(
        'Le mot de passe doit contenir au moins 8 caractères.',
        error: true,
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Les deux mots de passe ne correspondent pas.',
        error: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: password,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.check_circle,
              color: Color(0xFF2E7D32),
              size: 55,
            ),
            title: const Text(
              'Mot de passe modifié !',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Votre mot de passe a été réinitialisé avec succès. '
              'Vous pouvez maintenant vous connecter.',
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text('Retour à la connexion'),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF2E7D32),
        ),
        title: const Text(
          'Récupération du compte',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 25,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_reset,
                size: 75,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 20),

              Text(
                _step == 1
                    ? 'Mot de passe oublié ?'
                    : 'Créer un nouveau mot de passe',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _step == 1
                    ? 'Saisissez votre adresse e-mail pour recevoir un code de récupération.'
                    : 'Saisissez le code reçu par e-mail et choisissez votre nouveau mot de passe.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 30),

              // ADRESSE E-MAIL

              TextFormField(
                controller: _emailController,
                enabled: _step == 1 && !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Adresse e-mail',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_step == 1) ...[
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Envoyer le code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],

              if (_step == 2) ...[
                const SizedBox(height: 16),

                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Code de vérification',
                    prefixIcon: const Icon(Icons.pin_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Réinitialiser le mot de passe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _step = 1;
                            _codeController.clear();
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                  child: const Text(
                    'Modifier mon adresse e-mail',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
