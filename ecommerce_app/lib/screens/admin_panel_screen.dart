import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin_order_screen.dart';
import 'package:google_fonts/google_fonts.dart';


class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // 1. A key to validate our Form
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers for each text field
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // 3. NEW: Variables for category and discount
  String _selectedCategory = 'coins'; // Default category
  bool _hasDiscount = false;
  bool _isVintage = false; // NEW: Vintage flag
  int _discountPercentage = 0;
  double _discountedPrice = 0.0;

  // 4. A variable to show a loading spinner
  bool _isLoading = false;

  // 5. An instance of Firestore to save data
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 7. NEW: Function to calculate discounted price
  void _calculateDiscountedPrice() {
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    // VINTAGE ITEMS: Always 40% discount
    if (_isVintage) {
      _discountedPrice = price - (price * 40 / 100);
      _hasDiscount = true; // Auto-enable discount for vintage
      _discountPercentage = 40; // Fixed 40% for vintage
    }
    // REGULAR DISCOUNT ITEMS
    else if (_hasDiscount && _discountPercentage > 0) {
      _discountedPrice = price - (price * _discountPercentage / 100);
    }
    // NO DISCOUNT
    else {
      _discountedPrice = price;
      _discountPercentage = 0;
    }
    setState(() {});
  }

  // 8. Clean up the controllers
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _uploadProduct() async {
    // 1. First, check if all form fields are valid
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Show the loading spinner
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Get the text from our URL controller
      String imageUrl = _imageUrlController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      // 4. Auto-calculate discounted price before saving
      _calculateDiscountedPrice();

      // 5. Add the data to a new 'products' collection
      await _firestore.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'imageUrl': imageUrl,
        'category': _selectedCategory,
        'hasDiscount': _hasDiscount,
        'discountPercentage': _discountPercentage,
        'discountedPrice': _discountedPrice,
        'isVintage': _isVintage, // NEW: Save vintage flag
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 6. If successful, show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product uploaded successfully!')),
      );

      // 7. Clear all the text fields and reset form
      _formKey.currentState!.reset();
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageUrlController.clear();

      // 8. Reset category and discount fields
      setState(() {
        _selectedCategory = 'coins';
        _hasDiscount = false;
        _isVintage = false;
        _discountPercentage = 0;
        _discountedPrice = 0.0;
      });
    } catch (e) {
      // 9. If something went wrong, show an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload product: $e')),
      );
    } finally {
      // 10. ALWAYS hide the loading spinner
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Manage Orders Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Manage All Orders', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminOrderScreen(),
                      ),
                    );
                  },
                ),

                const Text(
                  'Add New Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Product Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),

                // Price Field
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    // Recalculate discount when price changes
                    _calculateDiscountedPrice();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Image URL Field
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an image URL';
                    }
                    if (!value.startsWith('http')) {
                      return 'Please enter a valid URL (e.g., http://...)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),


                // Upload Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _uploadProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Upload Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}