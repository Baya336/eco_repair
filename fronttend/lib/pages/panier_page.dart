
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'detail_produit_page.dart';

class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _cartItems = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // RÉCUPÉRER LE PANIER DEPUIS POSTGRESQL
  Future<void> _loadCart() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _authService.getCart();

      if (!mounted) return;

      setState(() {
        _cartItems = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // CHOISIR L'ICÔNE SELON LA CATÉGORIE
  IconData _getItemIcon(Map<String, dynamic> item) {
    final category = item['category'];

    if (category == 1) {
      return Icons.memory;
    }

    return Icons.devices;
  }

  // SUPPRIMER UN ARTICLE DU PANIER
  Future<void> _removeItem(int index) async {
    final item = _cartItems[index];
    final announcementId = item['announcement_id'];

    try {
      await _authService.removeFromCart(announcementId);

      if (!mounted) return;

      setState(() {
        _cartItems.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article retiré du panier.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen =
        MediaQuery.of(context).size.width < 380;

    return SafeArea(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14.0 : 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: const Color(0xFF4CAF50),
                            size: isSmallScreen ? 23 : 26,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'MON PANIER',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 16.5 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_cartItems.length} article(s)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 35,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _loadCart,
                                  child: const Text(
                                    'Réessayer',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _cartItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: Text(
                                  'Votre panier est vide.\nAjoutez un appareil ou une pièce depuis l\'accueil.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 650,
                                ),
                                child: ListView.separated(
                                  padding: EdgeInsets.all(
                                    isSmallScreen ? 14 : 20,
                                  ),
                                  itemCount: _cartItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = _cartItems[index];

                                    return Container(
                                      padding: EdgeInsets.all(
                                        isSmallScreen ? 10 : 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getItemIcon(item),
                                            color: const Color(0xFF2E7D32),
                                            size: isSmallScreen ? 28 : 32,
                                          ),
                                          SizedBox(
                                            width: isSmallScreen ? 8 : 12,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name']?.toString() ??
                                                      'Annonce',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize:
                                                        isSmallScreen ? 13 : 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Text(
                                                  '${item['type'] ?? ''} • ${item['location'] ?? 'Lieu non précisé'}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    isSmallScreen ? 6 : 12,
                                              ),
                                            ),
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DetailProduitPage(
                                                    item: item,
                                                  ),
                                                ),
                                              );

                                              // Actualiser le panier au retour
                                              _loadCart();
                                            },
                                            child: Text(
                                              'Demander',
                                              style: TextStyle(
                                                color:
                                                    const Color(0xFF2E7D32),
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    isSmallScreen ? 12.5 : 13.5,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            constraints:
                                                const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () {
                                              _removeItem(index);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
