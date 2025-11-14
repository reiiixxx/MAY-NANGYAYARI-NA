import 'package:ecommerce_app/screens/admin_chat_list_screen.dart';
import 'package:ecommerce_app/screens/chat_screen.dart';
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
      clipBehavior: Clip.antiAlias,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
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
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productData['name'] ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
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
                      ],
                    ),
                    Text(
                      '₱${productData['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
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
          return Center(child: Text('Error loading products: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No Products Available'));
        }

        final products = snapshot.data!.docs;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65,
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
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                _buildHamburgerMenuItems(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHamburgerMenuItems() {
    return Column(
      children: [
        if (_userRole == 'user')
          StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('chats').doc(_currentUser!.uid).snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    unreadCount = data['unreadByUserCount'] ?? 0;
                  }
                }
                return _buildHamburgerMenuItem(
                  icon: Icons.support_agent,
                  title: 'Contact Admin',
                  badgeCount: unreadCount,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChatScreen(chatRoomId: _currentUser!.uid),
                    ));
                  },
                );
              }),
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return _buildHamburgerMenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Cart',
              badgeCount: cart.itemCount,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartScreen()));
              },
            );
          },
        ),
        _buildHamburgerMenuItem(
          icon: Icons.receipt_long_outlined,
          title: 'My Orders',
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
          },
        ),
        if (_userRole == 'admin') ...[
           _buildHamburgerMenuItem(
            icon: Icons.chat_bubble_outline,
            title: 'View User Chats',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminChatListScreen()));
            },
          ),
          _buildHamburgerMenuItem(
            icon: Icons.dashboard_outlined,
            title: 'Admin Panel',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
            },
          ),
        ],
        _buildHamburgerMenuItem(
          icon: Icons.person_outlined,
          title: 'Profile',
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildHamburgerMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Badge(
        label: Text('$badgeCount'),
        isLabelVisible: badgeCount > 0,
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
      ),
      title: Text(title, style: const TextStyle(color: Color(0xFF2E7D32))),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useHamburgerMenu = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF8FFF5),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 40), // Placeholder for spacing
            // Logo
            SizedBox(
              height: 50,
              child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
            ),
            useHamburgerMenu
                ? IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF2E7D32)),
              onPressed: () => _showHamburgerMenu(context),
            )
                : _buildIconsRow(),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              _buildProductsGrid(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_userRole == 'user' && _currentUser != null)
          StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('chats').doc(_currentUser!.uid).snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    unreadCount = data['unreadByUserCount'] ?? 0;
                  }
                }
                return _buildModernIconButton(
                  icon: Icons.support_agent,
                  tooltip: 'Contact Admin',
                  badgeCount: unreadCount,
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChatScreen(chatRoomId: _currentUser!.uid),
                    ));
                  },
                );
              }),
        if (_userRole == 'admin')
          _buildModernIconButton(
            icon: Icons.chat_bubble_outline,
            tooltip: 'View User Chats',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminChatListScreen()));
            },
          ),
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return _buildModernIconButton(
              icon: Icons.shopping_bag_outlined,
              badgeCount: cart.itemCount,
              tooltip: 'Cart',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartScreen()));
              },
            );
          },
        ),
        _buildModernIconButton(
          icon: Icons.receipt_long_outlined,
          tooltip: 'My Orders',
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
          },
        ),
        if (_userRole == 'admin')
          _buildModernIconButton(
            icon: Icons.dashboard_outlined,
            tooltip: 'Admin Panel',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
            },
          ),
        _buildModernIconButton(
          icon: Icons.person_outlined,
          tooltip: 'Profile',
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
          },
        ),
      ],
    );
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
                    color: Colors.red, // Changed badge color for better visibility
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
}
