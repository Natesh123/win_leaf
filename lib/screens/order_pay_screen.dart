import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../models/order.dart';
import '../services/woocommerce_service.dart';
import 'payment_webview_screen.dart';

class OrderPayScreen extends StatefulWidget {
  final Order order;
  final bool autoStartPayment;

  const OrderPayScreen({super.key, required this.order, this.autoStartPayment = false});

  @override
  State<OrderPayScreen> createState() => _OrderPayScreenState();
}

class _OrderPayScreenState extends State<OrderPayScreen> {
  late Order _currentOrder;
  String? _paymentErrorMessage;
  bool _isRefreshing = false;
  final WooCommerceService _wooService = WooCommerceService();

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    if (widget.autoStartPayment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePayment();
      });
    }
  }

  Future<void> _handlePayment() async {
    if (_currentOrder.status == 'completed' || _currentOrder.status == 'processing') return;

    String? payUrl = _currentOrder.paymentUrl;
    String? orderKey = _currentOrder.orderKey;
    
    debugPrint('ORDER_PAY: Initiating payment for Order #${_currentOrder.id} (Key: $orderKey)');
    
    // If payUrl is missing or invalid, construct it carefully
    if (payUrl == null || payUrl.isEmpty || !payUrl.contains('key=')) {
      if (_currentOrder.id != null && orderKey != null) {
        // This specific format often bypasses "My Account" redirects in WooCommerce
        payUrl = 'https://winleafteas.com/checkout/order-pay/${_currentOrder.id}/?pay_for_order=true&key=$orderKey';
        // Add a timestamp to bypass any caching
        payUrl += '&t=${DateTime.now().millisecondsSinceEpoch}';
      }
    }
    
    // Add JWT Token to URL so WordPress can auto-login the user in the WebView
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isNotEmpty) {
        payUrl = '${payUrl ?? ""}&app_token=$token';
      }
    } catch (e) {
      debugPrint('ORDER_PAY: Failed to get JWT token: $e');
    }

    debugPrint('ORDER_PAY: Initiating Secure Bypass URL -> $payUrl');

    if (payUrl != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(url: payUrl!, title: 'Complete Payment'),
        ),
      );

      debugPrint('ORDER_PAY: Returned from WebView with Result -> $result');

      if (mounted) {
        if (result is String) {
          debugPrint('ORDER_PAY: Setting payment error message: $result');
          setState(() {
            _paymentErrorMessage = result;
          });
        }
        // Always refresh order to get latest status
        _refreshOrder();
      }
    }
  }

  Future<void> _refreshOrder() async {
    if (_currentOrder.id == null) return;
    
    debugPrint('ORDER_PAY: Refreshing order data and notes for ID: ${_currentOrder.id}');
    setState(() => _isRefreshing = true);
    try {
      // 1. Refresh order status
      final updatedOrder = await _wooService.getOrderById(_currentOrder.id!);
      
      // 2. Refresh order notes to find payment errors
      final notes = await _wooService.getOrderNotes(_currentOrder.id!);
      String? errorFromNotes;
      
      // Look for payment related errors in the notes
      for (var note in notes) {
        final lowerNote = note.toLowerCase();
        if (lowerNote.contains('failed') || lowerNote.contains('error') || lowerNote.contains('cancelled')) {
          // Extract the most recent error
          errorFromNotes = note.replaceAll(RegExp(r'<[^>]*>'), ''); // Strip HTML
          break;
        }
      }

      if (mounted) {
        setState(() {
          if (updatedOrder != null) _currentOrder = updatedOrder;
          
          if (_currentOrder.status == 'completed' || _currentOrder.status == 'processing') {
            _paymentErrorMessage = null;
            // Force trigger WooCommerce payment complete email
            _wooService.markOrderAsPaid(_currentOrder.id!);
          } else if (errorFromNotes != null) {
            _paymentErrorMessage = errorFromNotes;
            debugPrint('ORDER_PAY: Found error in notes -> $errorFromNotes');
          }
        });
      }
    } catch (e) {
      debugPrint('ORDER_PAY: Failed to refresh order: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Order Received',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshOrder,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Banner (Success if paid, Pending otherwise)
              if (_currentOrder.status == 'completed' || _currentOrder.status == 'processing')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Thank you. Your order is confirmed.',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Order #${_currentOrder.id} has been paid successfully.',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.orange, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Payment Pending',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please complete payment to confirm Order #${_currentOrder.id}.',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),

              // Native Status Banner (Matches Website Design)
              if (_paymentErrorMessage != null) _buildStatusBanner(),

              const SizedBox(height: 8),

              // Order Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    _buildTableHeader(),
                    
                    // Items
                    ..._currentOrder.lineItems.map((item) {
                      final total = double.tryParse(item.total ?? '0') ?? 0;
                      final tax = double.tryParse(item.totalTax ?? '0') ?? 0;
                      final inclusiveTotal = total + tax;
                      
                      return _buildTableRow(
                        item.name ?? 'Product',
                        '× ${item.quantity}',
                        '₹${inclusiveTotal.toStringAsFixed(2)}',
                      );
                    }),

                    // Subtotal
                    _buildSummaryRow('Subtotal:', '₹${_currentOrder.total}'),
                    
                    // Payment Method
                    _buildSummaryRow('Payment method:', _currentOrder.paymentMethodTitle),

                    // Order Status
                    _buildSummaryRow('Order Status:', _currentOrder.status?.toUpperCase() ?? 'PENDING'),

                    // Total
                    _buildTotalRow(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // PhonePe Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'PhonePe Payment Solutions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.payment, size: 20, color: AppColors.primaryOrange),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'All UPI apps, Debit and Credit Cards, and NetBanking accepted | Powered by PhonePe',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Privacy Policy Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Your personal data will be used to process your order, support your experience throughout this website, and for other purposes described in our privacy policy.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Terms and Conditions checkbox (Visual only)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the website terms and conditions *',
                      style: TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _currentOrder.status == 'completed' || _currentOrder.status == 'processing' ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: AppColors.primaryOrange.withOpacity(0.4),
                    disabledBackgroundColor: Colors.green.shade400,
                  ),
                  child: Text(
                    _currentOrder.status == 'completed' || _currentOrder.status == 'processing' 
                      ? 'Order Paid' 
                      : 'Pay For Order',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8), // Light red background matching website
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _paymentErrorMessage ?? '',
              style: const TextStyle(
                color: Color(0xFF9B1C1C), // Dark red text matching website
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: () => setState(() => _paymentErrorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Product', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Totals', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String qty, String total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(flex: 1, child: Text(qty, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey, fontSize: 13))),
          Expanded(flex: 2, child: Text(total, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 13))),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    String taxInfo = '';
    if (_currentOrder.totalTax != null && _currentOrder.totalTax != '0') {
      taxInfo = ' (includes ₹${_currentOrder.totalTax} GST)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('Total:', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18))),
          const SizedBox(width: 16),
          Expanded(
            flex: 2, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${_currentOrder.total}', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w900, fontSize: 20)),
                if (taxInfo.isNotEmpty)
                  Text(taxInfo, style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            )
          ),
        ],
      ),
    );
  }
}
