import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class ProductCard extends StatelessWidget {
  final String productName;
  final double price;
  final String imageUrl;
  final VoidCallback onTap;
  final bool hasDiscount;
  final int discountPercentage;

  const ProductCard({
    super.key,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.onTap,
    this.hasDiscount = false,
    this.discountPercentage = 0,
  });

  double get discountedPrice {
    if (hasDiscount && discountPercentage > 0) {
      return price - (price * discountPercentage / 100);
    }
    return price;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container
              AspectRatio(
                aspectRatio: 1.5,
                child: Stack(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    // Discount badge
                    if (hasDiscount && discountPercentage > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$discountPercentage% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Price section - CORRECTED VERSION
                    if (hasDiscount && discountPercentage > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Original price (grey with strikethrough)
                          Text(
                            '₱${price.toStringAsFixed(2)}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          // Discounted price (green, no strikethrough)
                          Text(
                            '₱${discountedPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                    // Regular price (green, no strikethrough)
                      Text(
                        '₱${price.toStringAsFixed(2)}',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}