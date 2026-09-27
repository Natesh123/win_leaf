import 'order.dart';

class Subscription {
  final int id;
  final String status;
  final String total;
  final String billingPeriod;
  final int billingInterval;
  final DateTime? nextPaymentDate;
  final DateTime? lastPaymentDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<OrderItem> lineItems;
  final String paymentMethodTitle;
  final Address? billing;
  final Address? shipping;
  final List<int> relatedOrders;
  final String shippingTotal;
  final String subtotal;
  final String discountTotal; // API: discount_total (e.g. '76.19')
  final String totalTax;      // API: total_tax (e.g. '15.24')

  Subscription({
    required this.id,
    required this.status,
    required this.total,
    required this.billingPeriod,
    required this.billingInterval,
    this.nextPaymentDate,
    this.lastPaymentDate,
    this.startDate,
    this.endDate,
    required this.lineItems,
    required this.paymentMethodTitle,
    this.billing,
    this.shipping,
    required this.relatedOrders,
    required this.shippingTotal,
    required this.subtotal,
    this.discountTotal = '0.00',
    this.totalTax = '0.00',
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Helper to parse dates correctly from WooCommerce API
    DateTime? parseDate(dynamic date) {
      if (date == null || date == "" || date.toString().contains("0000-00-00")) return null;
      try {
        String dateStr = date.toString();
        // WooCommerce REST API dates are usually UTC but often lack the 'Z' suffix
        if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
          dateStr += 'Z'; 
        }
        return DateTime.parse(dateStr).toLocal();
      } catch (e) {
        return null;
      }
    }

    final String status = (json['status'] ?? 'unknown').toString();
    
    final DateTime? start = parseDate(json['date_created_gmt'] ?? json['date_created']);
    final DateTime? last = parseDate(json['last_payment_date_gmt'] ?? json['last_payment_date']);

    return Subscription(
      id: json['id'] ?? 0,
      status: status,
      total: (json['total'] ?? '0.00').toString(),
      billingPeriod: (json['billing_period'] ?? 'month').toString(),
      billingInterval: int.tryParse(json['billing_interval']?.toString() ?? '1') ?? 1,
      nextPaymentDate: status.toLowerCase() == 'active' 
          ? parseDate(json['next_payment_date_gmt'] ?? json['next_payment_date'])
          : null,
      lastPaymentDate: last ?? start, // Fallback to start date if no payment yet
      startDate: start,
      endDate: parseDate(json['end_date_gmt'] ?? json['end_date']),
      lineItems: (json['line_items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      paymentMethodTitle: status.toLowerCase() != 'active' 
          ? 'Via Manual Renewal' 
          : (json['payment_method_title'] ?? 'Manual Renewal').toString(),
      billing: json['billing'] != null ? Address.fromJson(json['billing']) : null,
      shipping: json['shipping'] != null ? Address.fromJson(json['shipping']) : null,
      relatedOrders: List<int>.from(json['related_orders'] ?? []),
      shippingTotal: (json['shipping_total'] ?? '0.00').toString(),
      subtotal: (json['subtotal'] ?? json['total'] ?? '0.00').toString(),
      discountTotal: (json['discount_total'] ?? '0.00').toString(),
      totalTax: (json['total_tax'] ?? '0.00').toString(),
    );
  }

  String get billingSummary {
    String period = billingPeriod.toLowerCase();
    if (billingInterval > 1) {
      return "Every $billingInterval ${period}s";
    }
    return "Every $period";
  }
}
