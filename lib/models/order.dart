class Order {
  final int? id;
  final String? number;
  final String? status;
  final String? total;
  final DateTime? dateCreated;
  final List<OrderItem> lineItems;
  final Address? billing;
  final Address? shipping;
  final String paymentMethod;
  final String paymentMethodTitle;
  final bool setPaid;
  final String? paymentUrl;
  final String? orderKey;
  final String? totalTax;
  final String? shippingTotal;
  final String? discountTotal;
  final int? customerId;
  final List<Map<String, dynamic>>? metaData;

  Order({
    this.id,
    this.number,
    this.status,
    this.total,
    this.dateCreated,
    required this.lineItems,
    this.billing,
    this.shipping,
    this.paymentMethod = 'phonepe',
    this.paymentMethodTitle = 'PhonePe Payment Solutions',
    this.setPaid = false,
    this.paymentUrl,
    this.orderKey,
    this.totalTax,
    this.shippingTotal,
    this.discountTotal,
    this.customerId,
    this.metaData,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      number: json['number'],
      status: json['status'],
      total: json['total'],
      dateCreated: json['date_created'] != null ? DateTime.parse(json['date_created']) : null,
      lineItems: (json['line_items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      billing: json['billing'] != null ? Address.fromJson(json['billing']) : null,
      shipping: json['shipping'] != null ? Address.fromJson(json['shipping']) : null,
      paymentMethod: json['payment_method'] ?? '',
      paymentMethodTitle: json['payment_method_title'] ?? '',
      setPaid: json['status'] == 'processing' || json['status'] == 'completed',
      paymentUrl: json['payment_url'],
      orderKey: json['order_key'] ?? json['key'],
      totalTax: json['total_tax'],
      shippingTotal: json['shipping_total'],
      discountTotal: json['discount_total'],
      customerId: json['customer_id'],
      metaData: json['meta_data'] != null ? List<Map<String, dynamic>>.from(json['meta_data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'status': status ?? 'pending',
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': setPaid,
      if (billing != null) 'billing': billing!.toJson(),
      if (shipping != null) 'shipping': shipping!.toJson(),
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      if (customerId != null) 'customer_id': customerId,
      if (metaData != null) 'meta_data': metaData,
    };
  }
}

class OrderItem {
  final int productId;
  final int quantity;
  final String? name;
  final String? total;
  final String? totalTax;
  final String? subtotal;
  final String? subtotalTax;
  final List<Map<String, dynamic>>? metaData;

  OrderItem({
    required this.productId,
    required this.quantity,
    this.name,
    this.total,
    this.totalTax,
    this.subtotal,
    this.subtotalTax,
    this.metaData,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      name: (json['name'] ?? 'Unknown Item').toString(),
      total: (json['total'] ?? '0.00').toString(),
      totalTax: (json['total_tax'] ?? '0.00').toString(),
      subtotal: (json['subtotal'] ?? '0.00').toString(),
      subtotalTax: (json['subtotal_tax'] ?? '0.00').toString(),
      metaData: json['meta_data'] != null ? List<Map<String, dynamic>>.from(json['meta_data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      if (total != null) 'total': total,
      if (subtotal != null) 'subtotal': subtotal,
      if (metaData != null) 'meta_data': metaData,
    };
  }
}

class Address {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  Address({
    required this.firstName,
    required this.lastName,
    this.company = '',
    required this.address1,
    this.address2 = '',
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'IN',
    this.email = '',
    this.phone = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'email': email,
      'phone': phone,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? 'IN',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (firstName.isNotEmpty || lastName.isNotEmpty) parts.add('$firstName $lastName');
    if (company.isNotEmpty) parts.add(company);
    if (address1.isNotEmpty) parts.add(address1);
    if (address2.isNotEmpty) parts.add(address2);
    if (city.isNotEmpty || state.isNotEmpty || postcode.isNotEmpty) {
      String cityStateZip = [city, state, postcode].where((s) => s.isNotEmpty).join(', ');
      parts.add(cityStateZip);
    }
    if (country.isNotEmpty) parts.add(country);
    return parts.join('\n');
  }

  bool get isEmpty => firstName.isEmpty && address1.isEmpty;
}
