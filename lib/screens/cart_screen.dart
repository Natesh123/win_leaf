import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/cart_provider.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart';
import 'widgets/gradient_background.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart from server when entering screen
    Future.microtask(() {
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).loadCartFromServer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final items = cart.items;
        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: AppColors.textDark),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag, color: AppColors.primaryGold),
                  const SizedBox(width: 8),
                  Text(
                    'Cart',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cart.totalItems}',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              centerTitle: true,
              actions: [
                if (cart.isSyncing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => cart.loadCartFromServer(),
              color: AppColors.primaryOrange,
              child: items.isEmpty && !cart.isSyncing
                  ? _buildEmptyCart()
                  : Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  return _buildCartItem(context, cart, items[index]);
                                },
                              ),
                            ),
                            if (items.isNotEmpty) _buildFooter(context, cart),
                          ],
                        ),
                        if (items.isEmpty && cart.isSyncing)
                          const Center(
                            child: CircularProgressIndicator(color: AppColors.primaryOrange),
                          ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return ListView( // Use ListView for RefreshIndicator to work on empty state
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textGrey.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add products to get started',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, CartProvider cart, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: AppColors.backgroundLight,
              child: item.imagePath.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: item.imagePath,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: AppColors.textGrey, size: 30),
                      ),
                    )
                  : Image.asset(
                      item.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: AppColors.textGrey, size: 30),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim(),
                  style: GoogleFonts.montserrat(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                _buildPriceDetail(item),
              ],
            ),
          ),

          Column(
            children: [
              GestureDetector(
                onTap: () => cart.removeItem(item.name, subtitle: item.subtitle),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _qtyBtn(Icons.remove, () => cart.decreaseQty(item.name, subtitle: item.subtitle)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _qtyBtn(Icons.add, () => cart.increaseQty(item.name, subtitle: item.subtitle)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetail(CartItem item) {
    final bool isSubscription = item.subtitle.contains('Plan');
    // For subscriptions: item.price = ₹252 (billed every 3 months) — already shown in subtitle
    // For one-time: item.price = ₹280
    String mainPrice = '₹${(item.price * item.quantity).toStringAsFixed(2)}';

    // Billing info is already in the subtitle line ("3 Months Plan – ₹252.00 every 3 months")
    // so we don't repeat it here. Only add a note for one-time to clarify.
    String? note = (!isSubscription && item.quantity > 1) 
        ? '₹${item.price.toStringAsFixed(2)} × ${item.quantity}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mainPrice,
          style: GoogleFonts.montserrat(
            color: AppColors.primaryOrange,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (note != null)
          Text(
            note,
            style: GoogleFonts.montserrat(
              color: AppColors.textGrey,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primaryOrange),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                '₹${cart.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.websiteGradientStart, AppColors.websiteGradientEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'PROCEED TO CHECKOUT',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

