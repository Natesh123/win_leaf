import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/subscription.dart';
import '../services/woocommerce_service.dart';
import '../providers/subscription_provider.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailsScreen({super.key, required this.subscription});

  @override
  State<SubscriptionDetailsScreen> createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  final WooCommerceService _wcService = WooCommerceService();
  bool _isCancelling = false;

  Subscription get subscription => widget.subscription;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green;
      case 'on-hold': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return AppColors.textGrey;
    }
  }

  String _formatDate(DateTime? date, DateFormat format) {
    if (date == null) return '-';
    
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60 && difference.inMinutes >= 0) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24 && difference.inHours >= 0) {
      // Rounding: if minutes > 30, round up to next hour to match website
      int hours = difference.inHours;
      if (difference.inMinutes % 60 > 30) {
        hours += 1;
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    
    return format.format(date);
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel Subscription #${subscription.id}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. Your subscription will be cancelled immediately.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      final success = await _wcService.cancelSubscription(subscription.id);

      if (!mounted) return;

      if (success) {
        // Refresh the subscriptions list in the parent screen
        try {
          context.read<SubscriptionsProvider>().fetchSubscriptions();
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Subscription cancelled successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context); // Go back to subscriptions list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Failed to cancel subscription. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Subscription #${subscription.id}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryOrange, AppColors.primaryOrangeLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Status: ${subscription.status.toUpperCase()}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Renewed ${subscription.billingSummary}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Table
            _buildSectionTitle('General Details'),
            _buildInfoCard([
              _buildInfoRow('Start Date', _formatDate(subscription.startDate, dateFormat)),
              _buildInfoRow('Last Order Date', _formatDate(subscription.lastPaymentDate, dateFormat)),
              _buildInfoRow('Next Payment Date', _formatDate(subscription.nextPaymentDate, dateFormat)),
              _buildInfoRow('Payment', subscription.paymentMethodTitle),
            ]),
            const SizedBox(height: 24),

            // Subscription Totals — matches website layout exactly
            _buildSectionTitle('Subscription Totals'),
            Builder(builder: (context) {
              double subtotalWithTax = 0;
              for (var item in subscription.lineItems) {
                final double itemSubtotal = double.tryParse(item.subtotal ?? '0') ?? 0;
                final double itemSubtotalTax = double.tryParse(item.subtotalTax ?? '0') ?? 0;
                subtotalWithTax += itemSubtotal + itemSubtotalTax;
              }

              final double total = double.tryParse(subscription.total) ?? 0;
              final double shipping = double.tryParse(subscription.shippingTotal) ?? 0;
              final double discount = subtotalWithTax + shipping - total;

              final String freqLabel = subscription.billingInterval == 12 && subscription.billingPeriod == 'month'
                  ? '/ year'
                  : subscription.billingPeriod == 'year'
                      ? '/ year'
                      : '/ ${subscription.billingInterval > 1 ? "${subscription.billingInterval} months" : "month"}';

              final String everyLabel = subscription.billingInterval == 12 && subscription.billingPeriod == 'month'
                  ? 'every year'
                  : subscription.billingPeriod == 'year'
                      ? 'every year'
                      : 'every ${subscription.billingInterval > 1 ? "${subscription.billingInterval} months" : "month"}';

              return _buildInfoCard([
                ...subscription.lineItems.map((item) {
                  final double itemSubtotal = double.tryParse(item.subtotal ?? '0') ?? 0;
                  final double itemSubtotalTax = double.tryParse(item.subtotalTax ?? '0') ?? 0;
                  final double priceWithTax = itemSubtotal + itemSubtotalTax;

                  return _buildTotalRow(
                    '${item.name} × ${item.quantity}',
                    '₹${priceWithTax.toStringAsFixed(2)} $everyLabel',
                  );
                }),
                const Divider(height: 24),
                _buildTotalRow('Subtotal', '₹${subtotalWithTax.toStringAsFixed(2)}'),
                if (discount > 0.01)
                  _buildTotalRow(
                    'Discount',
                    '-₹${discount.toStringAsFixed(2)}',
                    isDiscount: true,
                  ),
                _buildTotalRow(
                  'Shipping',
                  shipping == 0 ? 'Free shipping' : '₹${shipping.toStringAsFixed(2)}',
                ),
                const Divider(height: 16),
                _buildTotalRow('Total', '₹${total.toStringAsFixed(2)} $freqLabel', isBold: true),
              ]);
            }),

            const SizedBox(height: 24),

            // Addresses
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAddressBlock('Billing Address', subscription.billing?.fullAddress ?? 'N/A')),
                const SizedBox(width: 16),
                Expanded(child: _buildAddressBlock('Shipping Address', subscription.shipping?.fullAddress ?? 'N/A')),
              ],
            ),
            const SizedBox(height: 32),

            // Related Orders
            if (subscription.relatedOrders.isNotEmpty) ...[
              _buildSectionTitle('Related Orders'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardGrey),
                ),
                child: Column(
                  children: subscription.relatedOrders.map((orderId) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('View order details'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to order details if needed
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Actions
            if (subscription.status != 'cancelled')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : () => _confirmCancel(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                        )
                      : const Text(
                          'Cancel Subscription',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : (isBold ? AppColors.primaryOrange : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBlock(String title, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardGrey),
          ),
          child: Text(
            address,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }
}
