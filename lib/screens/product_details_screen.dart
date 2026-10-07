import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/cart_provider.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cart_screen.dart';
import 'auth_screen.dart';
import 'widgets/gradient_background.dart';
import '../services/auth_service.dart';
import '../models/testimonial.dart';
import '../providers/product_details_provider.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailsProvider(product),
      child: Consumer<ProductDetailsProvider>(

        builder: (context, provider, child) {
          return GradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: AppColors.textDark),
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    product.name,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textDark,
                      fontSize: 16,
                    ),
                  ),
                ),
                actions: [
                  Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                        child: Badge(
                          isLabelVisible: cart.totalItems > 0,
                          label: Text(
                            cart.totalItems.toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryOrange),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImage(provider),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.categories.isNotEmpty ? product.categories[0].toUpperCase() : 'TEA',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textGrey,
                              letterSpacing: 1.2,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            product.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '₹${product.price.toStringAsFixed(2)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '— or subscribe and save up to 20%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (product.regularPrice > product.price) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '₹${product.regularPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textGrey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(((product.regularPrice - product.price) / product.regularPrice) * 100).toInt()}% OFF',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildRewardsBanner(),
                          const SizedBox(height: 24),
                          _buildPurchaseOptions(provider),
                          const SizedBox(height: 32),
                          _buildTabs(provider),
                          const SizedBox(height: 20),
                          _buildTabContent(provider),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomBar(context, provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(ProductDetailsProvider provider) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              color: AppColors.backgroundLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: kIsWeb
                  ? Image.network(
                      product.images.isNotEmpty ? product.images[provider.selectedImageIndex] : '',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.shopping_bag, size: 100, color: Colors.grey),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.images.isNotEmpty 
                          ? product.images[provider.selectedImageIndex] 
                          : '',
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.shopping_bag, size: 100, color: Colors.grey),
                      ),
                    ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'FREE 50G SAMPLE INCLUDED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (product.images.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: product.images.length,
                itemBuilder: (context, index) {
                  final isSelected = provider.selectedImageIndex == index;
                  return GestureDetector(
                    onTap: () => provider.setSelectedImageIndex(index),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGold : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: kIsWeb
                          ? Image.network(
                              product.images[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, size: 20),
                            )
                          : CachedNetworkImage(
                              imageUrl: product.images[index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error_outline, size: 20),
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRewardsBanner() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Purchase this product now and earn ${product.points} Points!',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'First Order Special!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                    ),
                    Text(
                      'Get 1 FREE sample of 50g tea with this pack.',
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 12),
        Text(
          product.description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
          style: const TextStyle(height: 1.5, color: AppColors.textDark),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _FeatureItem(icon: Icons.eco, label: '100% Organic'),
            _FeatureItem(icon: Icons.no_food_outlined, label: 'No Preservatives'),
            _FeatureItem(icon: Icons.local_shipping_outlined, label: 'Ships in 24h'),
          ],
        ),
      ],
    );
  }

  Widget _buildPurchaseOptions(ProductDetailsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioOption(
          'One-time purchase', 
          'Standard delivery', 
          null,
          null,
          provider.purchaseOption == 'One-time', 
          () => provider.setPurchaseOption('One-time'),
          singlePrice: '₹${product.price.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 12),
        _buildRadioOption(
          'Subscribe & Save upto 20%', 
          provider.selectedPlan.billingLabel,
          provider.selectedPlan.planOriginalPrice,
          provider.selectedPlan.planTotalPrice,
          provider.purchaseOption == 'Subscribe', 
          () => provider.setPurchaseOption('Subscribe'),
          isRecommended: true
        ),

        if (provider.purchaseOption == 'Subscribe') ...[
          const SizedBox(height: 20),
          const Text('Select subscription plan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardGrey),
            ),
            child: DropdownButtonHideUnderline(
            child: DropdownButton<SubscriptionPlan>(
                value: provider.selectedPlan,
                isExpanded: true,
                items: provider.plans.map<DropdownMenuItem<SubscriptionPlan>>((SubscriptionPlan plan) {
                  return DropdownMenuItem<SubscriptionPlan>(
                    value: plan,
                    child: Text(plan.label, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                  );
                }).toList(),
                onChanged: (SubscriptionPlan? val) {
                  if (val != null) provider.setSelectedPlan(val);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadioOption(String title, String subtitle, double? originalPrice, double? discountedPrice, bool isSelected, VoidCallback onTap, {bool isRecommended = false, String? singlePrice}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.backgroundLight,
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off, 
              color: isSelected ? AppColors.primaryOrange : AppColors.textGrey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title, 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('RECOMMENDED', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: const TextStyle(color: AppColors.textGrey, fontSize: 10), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Show crossed-out original + discounted price (like website)
            if (originalPrice != null && discountedPrice != null) ...
              [
                Text(
                  '₹${originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '₹${discountedPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                ),
              ]
            else
              Text(
                singlePrice ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(ProductDetailsProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabItem(provider, 'Description'),
          _buildTabItem(provider, 'Additional information'),
          _buildTabItem(provider, 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildTabItem(ProductDetailsProvider provider, String title) {
    bool isActive = provider.activeTab == title;
    return GestureDetector(
      onTap: () => provider.setActiveTab(title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primaryGold : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.textDark : AppColors.textGrey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ProductDetailsProvider provider) {
    switch (provider.activeTab) {
      case 'Additional information':
        return _buildAdditionalInfo();
      case 'Reviews':
        return _buildReviewsSection(provider);
      case 'Description':
      default:
        return _buildProductDescription();
    }
  }

  Widget _buildAdditionalInfo() {
    List<Widget> rows = [];
    
    if (product.weight.isNotEmpty) {
      rows.add(_buildInfoRow('Weight', product.weight));
      rows.add(const Divider(color: Colors.white24));
    }
    
    if (product.dimensions['length'] != '') {
      rows.add(_buildInfoRow('Dimensions', '${product.dimensions['length']} × ${product.dimensions['width']} × ${product.dimensions['height']} cm'));
      rows.add(const Divider(color: Colors.white24));
    }
    
    for (var attr in product.attributes) {
      if (attr['visible'] == true) {
        String label = attr['name'] ?? '';
        List<dynamic> options = attr['options'] ?? [];
        String value = options.join(', ');
        
        if (label.toLowerCase() == 'weight' && product.weight.isNotEmpty) continue;
        
        rows.add(_buildInfoRow(label, value));
        rows.add(const Divider(color: Colors.white24));
      }
    }

    if (rows.isEmpty) {
      return const Text('No additional information available.', style: TextStyle(color: AppColors.textGrey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ProductDetailsProvider provider) {
    if (provider.isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    final TextEditingController reviewController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.productReviews.isEmpty)
          const Text('There are no reviews yet.', style: TextStyle(color: AppColors.textDark))
        else
          Column(
            children: provider.productReviews.map((review) => _buildReviewItem(review)).toList(),
          ),
        const SizedBox(height: 32),
        Text('Be the first to review "${product.name}"', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        const Text('Your rating *', style: TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) => IconButton(
            onPressed: () => provider.setSelectedRating(index + 1),
            icon: Icon(
              index < provider.selectedRating ? Icons.star : Icons.star_border, 
              color: AppColors.primaryGold,
            ),
          )),
        ),
        const SizedBox(height: 20),
        const Text('Your review *', style: TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 8),
        TextField(
          controller: reviewController,
          maxLines: 4,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            fillColor: AppColors.backgroundLight,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Type your review here...',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.isSubmittingReview ? null : () async {
              final success = await provider.submitReview(reviewController.text);
              if (success) {
                reviewController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: provider.isSubmittingReview 
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(Testimonial review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(review.image),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: AppColors.primaryGold,
                        size: 14,
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment, style: const TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductDetailsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.backgroundLight,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            bool loggedIn = await AuthService().isLoggedIn();
            if (!loggedIn) {
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
              return;
            }

            CartProvider().addItem(
              CartItem(
                id: product.id,
                name: product.name,
                subtitle: provider.purchaseOption == 'Subscribe' 
                    ? '${provider.selectedPlan.name} – ${provider.selectedPlan.billingLabel}' 
                    : product.shortDescription.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim(),
                imagePath: product.images.isNotEmpty ? product.images[0] : 'assets/images/product_red.png',
                price: provider.purchaseOption == 'Subscribe' 
                    ? provider.selectedPlan.billingPrice 
                    : product.price, 
                slug: product.slug,
                extraData: provider.purchaseOption == 'Subscribe' 
                    ? {'convert_to_sub_${product.id}': '${provider.selectedPlan.months == 12 ? '1_year' : '${provider.selectedPlan.months}_month'}'} 
                    : null,
              ),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Added to Cart! 🛒'),
                  backgroundColor: AppColors.primaryOrange,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'View Cart',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.shopping_bag_outlined),
          label: Text(
            provider.purchaseOption == 'Subscribe' ? 'Sign Up Now' : 'Add to Cart',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
      ],
    );
  }
}
