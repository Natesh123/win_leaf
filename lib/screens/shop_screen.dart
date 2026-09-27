import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/product.dart';
import '../services/woocommerce_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import '../services/auth_service.dart';
import '../models/cart_provider.dart';
import '../providers/shop_provider.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShopProvider(),
      child: const _ShopScreenBody(),
    );
  }
}

class _ShopScreenBody extends StatefulWidget {
  const _ShopScreenBody();

  @override
  State<_ShopScreenBody> createState() => _ShopScreenBodyState();
}

class _ShopScreenBodyState extends State<_ShopScreenBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ShopProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadMoreProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Shop',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ShopProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildOfferBanner(provider),
              Expanded(
                child: _buildProductGrid(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfferBanner(ShopProvider provider) {
    // Banner hidden as requested
    return const SizedBox.shrink();

    /*
    String title = provider.isFirstOrder ? 'First Order Special!' : 'Member Rewards!';
    String subtitle = provider.isFirstOrder 
        ? 'Get 50g FREE Tea Pack on your first order' 
        : 'Earn 10 Reward Points on your next purchase';
    String highlightText = provider.isFirstOrder ? 'Use Code: FREE50' : 'Points Inside';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.websiteGradientEnd, AppColors.websiteGradientStart],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    provider.isFirstOrder ? Icons.card_giftcard : Icons.stars, 
                    color: Colors.white, 
                    size: 28
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    highlightText,
                    style: GoogleFonts.montserrat(
                      color: AppColors.websiteGradientStart,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Exclusive for you',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    */
  }

  Widget _buildProductGrid(ShopProvider provider) {
    if (provider.products.isEmpty && provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && provider.products.isEmpty) {
      return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: AppColors.textDark)));
    } else if (provider.products.isEmpty) {
      return const Center(child: Text('No products found', style: TextStyle(color: AppColors.textDark)));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.products.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildProductCard(context, provider.products[index]);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      color: AppColors.backgroundLight,
                      child: Center(
                        child: kIsWeb
                            ? Image.network(
                                product.images.isNotEmpty ? product.images[0] : '',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 50,
                                  color: AppColors.cardGrey,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: product.images.isNotEmpty ? product.images[0] : '',
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 50,
                                  color: AppColors.cardGrey,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (product.onSale)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toInt()}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                          fontSize: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
