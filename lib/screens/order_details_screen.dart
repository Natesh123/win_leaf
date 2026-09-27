import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/order.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status ?? 'unknown';
    final dateStr = order.dateCreated != null 
        ? DateFormat('MMMM d, yyyy HH:mm').format(order.dateCreated!) 
        : 'N/A';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Order #${order.id ?? order.number}', 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(status),
            const SizedBox(height: 24),
            _buildSectionTitle('Order Summary'),
            _buildSummaryCard(dateStr),
            const SizedBox(height: 24),
            _buildSectionTitle('Items'),
            _buildItemsList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Shipping Information'),
            _buildShippingCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Billing Information'),
            _buildBillingCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String dateStr) {
    double subtotalWithTax = 0;
    for (var item in order.lineItems) {
      final double itemSubtotal = double.tryParse(item.subtotal ?? '0') ?? 0;
      final double itemSubtotalTax = double.tryParse(item.subtotalTax ?? '0') ?? 0;
      subtotalWithTax += itemSubtotal + itemSubtotalTax;
    }

    final double discount = double.tryParse(order.discountTotal ?? '0') ?? 0;
    final double shipping = double.tryParse(order.shippingTotal ?? '0') ?? 0;
    final double tax = double.tryParse(order.totalTax ?? '0') ?? 0;
    final double total = double.tryParse(order.total ?? '0') ?? 0;

    return _buildInfoCard([
      _buildInfoRow('Order Date', dateStr),
      _buildInfoRow('Payment Method', order.paymentMethodTitle),
      _buildInfoRow('Subtotal', '₹${subtotalWithTax.toStringAsFixed(2)}'),
      if (discount > 0)
        _buildInfoRow('Discount', '-₹${discount.toStringAsFixed(2)}'),
      if (shipping > 0)
        _buildInfoRow('Shipping', '₹${shipping.toStringAsFixed(2)}'),
      if (tax > 0)
        _buildInfoRow('GST (5%)', '₹${tax.toStringAsFixed(2)}'),
      _buildInfoRow('Total Amount', '₹${total.toStringAsFixed(2)}', isBold: true),
    ]);
  }

  Widget _buildStatusCard(String status) {
    final color = _getStatusColor(status);
    IconData icon;
    switch (status.toLowerCase()) {
      case 'completed': icon = Icons.check_circle_outline; break;
      case 'processing': icon = Icons.sync; break;
      case 'pending': icon = Icons.hourglass_empty; break;
      case 'cancelled': icon = Icons.cancel_outlined; break;
      case 'failed': icon = Icons.error_outline; break;
      default: icon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color, 
              fontWeight: FontWeight.w900, 
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Order Status',
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
                color: isBold ? AppColors.primaryOrange : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: order.lineItems.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
        itemBuilder: (context, index) {
          final item = order.lineItems[index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryOrange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name ?? 'Product', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text('Qty: ${item.quantity}', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final double lineSubtotal = double.tryParse(item.subtotal ?? '0') ?? 0;
                    final double lineSubtotalTax = double.tryParse(item.subtotalTax ?? '0') ?? 0;
                    final double priceWithTax = lineSubtotal + lineSubtotalTax;
                    return Text('₹${priceWithTax.toStringAsFixed(2)}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryOrange));
                  }
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShippingCard() {
    final shipping = order.shipping;
    final billing = order.billing;
    
    // If shipping is empty but billing is not, use billing
    final displayAddress = (shipping != null && !shipping.isEmpty) ? shipping : billing;

    if (displayAddress == null || displayAddress.isEmpty) {
      return _buildEmptyCard('No shipping information available');
    }

    return _buildAddressCard(
      '${displayAddress.firstName} ${displayAddress.lastName}',
      displayAddress.fullAddress,
      null,
      null,
    );
  }

  Widget _buildBillingCard() {
    if (order.billing == null || order.billing!.isEmpty) {
      return _buildEmptyCard('No billing information available');
    }
    return _buildAddressCard(
      '${order.billing!.firstName} ${order.billing!.lastName}',
      order.billing!.fullAddress,
      order.billing!.phone.isNotEmpty ? order.billing!.phone : null,
      order.billing!.email.isNotEmpty ? order.billing!.email : null,
    );
  }

  Widget _buildAddressCard(String name, String address, String? phone, String? email) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.textGrey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(address, style: const TextStyle(color: AppColors.textDark, height: 1.5, fontSize: 14)),
              ),
            ],
          ),
          if (phone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_outlined, color: AppColors.textGrey, size: 20),
                const SizedBox(width: 8),
                Text(phone, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
              ],
            ),
          ],
          if (email != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email_outlined, color: AppColors.textGrey, size: 20),
                const SizedBox(width: 8),
                Text(email, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2), style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'processing': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }
}
