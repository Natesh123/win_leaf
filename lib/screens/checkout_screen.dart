import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/cart_provider.dart';
import '../models/order.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/checkout_provider.dart';
import 'order_pay_screen.dart';
import 'payment_webview_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  static final _formKey = GlobalKey<FormState>();

  Future<void> _handlePlaceOrder(BuildContext context, CheckoutProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required billing details correctly.')),
      );
      return;
    }

    final createdOrder = await provider.placeOrder();
    
    if (createdOrder != null) {
      if (context.mounted) {
        // Construct proper WooCommerce payment URL
        String? payUrl = createdOrder.paymentUrl;
        if (createdOrder.id != null && createdOrder.orderKey != null) {
          payUrl = 'https://winleafteas.com/checkout/order-pay/${createdOrder.id}/?pay_for_order=true&key=${createdOrder.orderKey}';
        }

        if (payUrl != null && payUrl.isNotEmpty) {
          // Add JWT Token to URL so WordPress can auto-login the user in the WebView
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('jwt_token') ?? '';
            if (token.isNotEmpty) {
              payUrl = '$payUrl&app_token=$token';
            }
          } catch (e) {
            debugPrint('CHECKOUT: Failed to get JWT token: $e');
          }

          // Seamlessly transition to payment
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(url: payUrl!, title: 'Complete Payment'),
            ),
          );
        } else {
          _showSuccessDialog(context);
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place order. Please check your connection or try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed!'),
        content: const Text(
          'Your order has been successfully placed. If you have been redirected to payment, please complete it there. We will contact you soon.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutProvider()..loadUserDetails(),
      child: Consumer2<CheckoutProvider, CartProvider>(
        builder: (context, provider, cart, child) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              title: Text(
                'Checkout',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Billing details'),
                          const SizedBox(height: 16),
                          _buildTextField('First name *', provider.firstNameController),
                          const SizedBox(height: 12),
                          _buildTextField('Last name *', provider.lastNameController),
                          const SizedBox(height: 12),
                          _buildTextField('Company name (optional)', provider.companyController, isRequired: false),
                          const SizedBox(height: 12),
                          _buildReadOnlyField('Country / Region *', 'India'),
                          const SizedBox(height: 12),
                          _buildTextField('Street address *', provider.address1Controller, hint: 'House number and street name'),
                          const SizedBox(height: 12),
                          _buildTextField('', provider.address2Controller, hint: 'Apartment, suite, unit, etc. (optional)', isRequired: false),
                          const SizedBox(height: 12),
                          _buildTextField('Town / City *', provider.cityController),
                          const SizedBox(height: 12),
                          _buildStateDropdown(provider),
                          const SizedBox(height: 12),
                          _buildTextField('PIN Code *', provider.postcodeController, keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildTextField('Phone *', provider.phoneController, keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _buildTextField('Email address *', provider.emailController, keyboardType: TextInputType.emailAddress),
                          
                          const SizedBox(height: 32),
                          _buildSectionTitle('Your order'),
                          const SizedBox(height: 16),
                          _buildOrderSummary(cart),
                          
                          const SizedBox(height: 32),
                          _buildSectionTitle('Payment'),
                          const SizedBox(height: 16),
                          _buildPaymentSection(),
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: provider.isLoading ? null : () => _handlePlaceOrder(context, provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGold,
                                foregroundColor: AppColors.textDark,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: AppColors.primaryGold.withOpacity(0.6),
                              ),
                              child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textDark),
                                    ),
                                  )
                                : Text(
                                    'Place Order',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = true, String? hint, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardGrey),
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (label.contains('Email') && value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Enter a valid email';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardGrey),
          ),
          child: Text(
            value,
            style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown(CheckoutProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State *',
          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: provider.selectedState,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardGrey),
            ),
          ),
          items: provider.states.map((String state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state, style: GoogleFonts.montserrat(fontSize: 14)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              provider.setSelectedState(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Product', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Subtotal', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white54),
          ...cart.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.name} x ${item.quantity}',
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
                  ),
                ),
                Text(
                  '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          )),
          const Divider(color: Colors.white54),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.montserrat(color: Colors.white)),
              Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.montserrat(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${cart.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    '(includes ₹${(cart.totalAmount * 0.05).toStringAsFixed(2)} GST 5%)',
                    style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radio_button_checked, color: AppColors.primaryOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PhonePe Payment Solutions',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.network(
                          'https://download.logo.wine/logo/PhonePe/PhonePe-Logo.wine.png',
                          height: 30,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text('UPI, Credit/Debit Card, Netbanking', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'All UPI apps, Debit and Credit Cards, and NetBanking accepted | Powered by PhonePe',
              style: TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
