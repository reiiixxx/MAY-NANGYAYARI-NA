import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart';
import 'package:ecommerce_app/screens/profile_screen.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'];
        });
      }
    } catch (e) {
      print("DEBUG: Error fetching user role: $e");
    }
  }

  Widget _buildProductCard(Map<String, dynamic> productData, String productId) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productData: productData,
                productId: productId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 150,
                width: double.infinity,
                color: const Color(0xFFF8FFF5),
                child: productData['imageUrl'] != null &&
                    productData['imageUrl'].isNotEmpty
                    ? Image.network(
                  productData['imageUrl'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFF4CAF50),
                        size: 50,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4CAF50)),
                        ),
                      ),
                    );
                  },
                )
                    : Container(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Color(0xFF4CAF50),
                    size: 50,
                  ),
                ),
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    productData['name'] ?? 'Unnamed Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Product Description
                  if (productData['description'] != null)
                    Text(
                      productData['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  // Price
                  Text(
                    '\$${productData['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Add to Cart Button
                  Container(
                    width: double.infinity,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // Add to cart functionality
                        final cartProvider =
                        Provider.of<CartProvider>(context, listen: false);
                        cartProvider.addToCart(
                          productId: productId,
                          productName: productData['name'] ?? 'Product',
                          price: (productData['price'] as num).toDouble(),
                          imageUrl: productData['imageUrl'] ?? '',
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${productData['name']} to cart'),
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading products: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 50,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Products Available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check back later for new meal kits!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final productDoc = products[index];
            final productData = productDoc.data() as Map<String, dynamic>;
            return _buildProductCard(productData, productDoc.id);
          },
        );
      },
    );
  }

  // ... (Keep all your existing methods: _buildHamburgerMenu, _showHamburgerMenu, 
  // _buildHamburgerMenuItems, _buildHamburgerMenuItem, _buildIconsRow, 
  // _buildAllIcons, _buildModernIconButton, _buildFoodIcon)

  // These methods remain exactly the same as in your original code
  Widget _buildHamburgerMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return _buildModernIconButton(
              icon: Icons.shopping_bag_outlined,
              badgeCount: cart.itemCount,
              tooltip: 'Cart',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CartScreen(),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 8),
        _buildModernIconButton(
          icon: Icons.menu,
          tooltip: 'Menu',
          onPressed: () {
            _showHamburgerMenu(context);
          },
        ),
      ],
    );
  }

  void _showHamburgerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF2E7D32)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                ..._buildHamburgerMenuItems(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildHamburgerMenuItems() {
    return [
      _buildHamburgerMenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'My Orders',
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OrderHistoryScreen(),
            ),
          );
        },
      ),
      if (_userRole == 'admin')
        _buildHamburgerMenuItem(
          icon: Icons.dashboard_outlined,
          title: 'Admin Panel',
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminPanelScreen(),
              ),
            );
          },
        ),
      _buildHamburgerMenuItem(
        icon: Icons.person_outlined,
        title: 'Profile',
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildHamburgerMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FFF5),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Color(0xFF2E7D32)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildIconsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: _buildAllIcons(),
    );
  }

  List<Widget> _buildAllIcons() {
    return [
      Consumer<CartProvider>(
        builder: (context, cart, child) {
          return _buildModernIconButton(
            icon: Icons.shopping_bag_outlined,
            badgeCount: cart.itemCount,
            tooltip: 'Cart',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          );
        },
      ),
      _buildModernIconButton(
        icon: Icons.receipt_long_outlined,
        tooltip: 'My Orders',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OrderHistoryScreen(),
            ),
          );
        },
      ),
      if (_userRole == 'admin')
        _buildModernIconButton(
          icon: Icons.dashboard_outlined,
          tooltip: 'Admin Panel',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminPanelScreen(),
              ),
            );
          },
        ),
      _buildModernIconButton(
        icon: Icons.person_outlined,
        tooltip: 'Profile',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildModernIconButton({
    required IconData icon,
    required String tooltip,
    int badgeCount = 0,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
                onPressed: onPressed,
                padding: EdgeInsets.zero,
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(width: 1.5, color: Colors.white),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useHamburgerMenu = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FFF5),
        elevation: 0,
        title: Row(
          children: [
            // Logo
            Expanded(
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // MEAL KIT text
                      Text(
                        "MEAL KIT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                          letterSpacing: 1.2,
                        ),
                      ),

                      // SUBSCRIPTION text
                      Text(
                        "SUBSCRIPTION",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Icons on right
            Expanded(
              child: useHamburgerMenu
                  ? _buildHamburgerMenu()
                  : _buildIconsRow(),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Message
                  Text(
                    "Welcome to Your Meal Kit!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Your culinary journey starts here. Discover delicious recipes and fresh ingredients delivered to your door.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Products Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Available Meal Kits",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Products Grid
            Expanded(
              child: _buildProductsGrid(),
            ),

            // Bottom decorative elements
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFoodIcon(Icons.local_pizza, const Color(0xFFFF9800)),
                  _buildFoodIcon(Icons.emoji_food_beverage, const Color(0xFF4CAF50)),
                  _buildFoodIcon(Icons.cake, const Color(0xFFE91E63)),
                  _buildFoodIcon(Icons.free_breakfast, const Color(0xFF795548)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on CartProvider {
  void addToCart({required String productId, required productName, required double price, required imageUrl}) {}
}