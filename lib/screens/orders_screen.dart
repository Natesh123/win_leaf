import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/url_launcher_service.dart';
import 'order_details_screen.dart';
import 'order_pay_screen.dart';
import 'payment_webview_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Consumer<OrderProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: provider.fetchOrders,
                );
              },
            ),
          ],
        ),
        backgroundColor: AppColors.backgroundLight,
        body: Consumer<OrderProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(provider.error!, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: provider.fetchOrders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No orders found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: provider.fetchOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.orders.length,
                itemBuilder: (context, index) {
                  final order = provider.orders[index];
                  return OrderCard(order: order);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status ?? 'unknown';
    final dateStr = order.dateCreated != null 
        ? DateFormat('yyyy-MM-dd HH:mm').format(order.dateCreated!) 
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order #${order.id ?? order.number ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: $dateStr', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 4),
              Text('Total: ₹${order.total ?? "0"}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(),
                ...order.lineItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.name ?? "Product", style: const TextStyle(fontSize: 13))),
                      Text('x${item.quantity}', style: const TextStyle(color: AppColors.textGrey)),
                      const SizedBox(width: 16),
                      Builder(
                        builder: (context) {
                          final double lineSubtotal = double.tryParse(item.subtotal ?? '0') ?? 0;
                          final double lineSubtotalTax = double.tryParse(item.subtotalTax ?? '0') ?? 0;
                          final double priceWithTax = lineSubtotal + lineSubtotalTax;
                          return Text('₹${priceWithTax.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600));
                        }
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                const Text('Shipping Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(),
                Builder(builder: (context) {
                  final displayAddress = (order.shipping != null && !order.shipping!.isEmpty) 
                      ? order.shipping 
                      : order.billing;
                  
                  if (displayAddress == null || displayAddress.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No address details available', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    );
                  }
                  
                  return Column(
                    children: [
                      _buildDetailItem('Full Name', '${displayAddress.firstName} ${displayAddress.lastName}'),
                      _buildDetailItem('Address', displayAddress.address1),
                      if (displayAddress.address2.isNotEmpty) _buildDetailItem('', displayAddress.address2),
                      _buildDetailItem('City', displayAddress.city),
                      if (order.billing != null && order.billing!.phone.isNotEmpty) 
                        _buildDetailItem('Phone', order.billing!.phone),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Pay Button
                    if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'failed')
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: () {
                              // Construct proper WooCommerce payment URL to ensure it lands on the payment page
                              String? payUrl = order.paymentUrl;
                              if (order.id != null && order.orderKey != null) {
                                payUrl = 'https://winleafteas.com/checkout/order-pay/${order.id}/?pay_for_order=true&key=${order.orderKey}';
                              } else if (payUrl != null && order.orderKey != null && !payUrl.contains('key=')) {
                                payUrl += (payUrl.contains('?') ? '&' : '?') + 'pay_for_order=true&key=${order.orderKey}';
                              }
                              
                              if (payUrl != null && payUrl.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderPayScreen(order: order),
                                  ),
                                ).then((_) {
                                  // Refresh orders if payment might have been completed
                                  if (context.mounted) {
                                    context.read<OrderProvider>().fetchOrders();
                                  }
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Payment link not available')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    
                    // View Button
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: (status.toLowerCase() != 'cancelled' && status.toLowerCase() != 'completed' && order.id != null) ? 8 : 0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),

                    // Cancel Button
                    if (status.toLowerCase() != 'cancelled' && status.toLowerCase() != 'completed' && order.id != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await context.read<OrderProvider>().cancelOrder(order.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(success ? 'Order cancelled successfully' : 'Failed to cancel order')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'processing': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }
}
