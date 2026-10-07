class FaqResponse {
  final String text;
  final List<String>? options;
  final String? type;

  FaqResponse({required this.text, this.options, this.type});
}

class FaqService {
  static final FaqService _instance = FaqService._internal();
  factory FaqService() => _instance;
  FaqService._internal();

  // Known product price catalog per brand variant
  final List<Map<String, dynamic>> _productCatalog = [
    {
      'keywords': ['premium'],
      'name': 'Win Leaf Premium Tea',
      'prices': {'250g': 149, '500g': 280, '1kg': 520},
      'defaultPrice': '250g is ₹149, 500g is ₹280, and 1kg is ₹520',
    },
    {
      'keywords': ['classic'],
      'name': 'Win Leaf Classic Tea',
      'prices': {'250g': 109, '500g': 210, '1kg': 390},
      'defaultPrice': '250g is ₹109 and 500g is ₹210',
    },
    {
      'keywords': ['hotel'],
      'name': 'Win Leaf Hotel Blend Tea',
      'prices': {'500g': 220, '1kg': 400},
      'defaultPrice': '1kg is ₹400 and 500g is ₹220',
    },
    {
      'keywords': ['masala'],
      'name': 'Win Leaf Masala Chai',
      'prices': {'250g': 129, '500g': 245},
      'defaultPrice': '250g is ₹129 and 500g is ₹245',
    },
    {
      'keywords': ['green'],
      'name': 'Win Leaf Green Tea',
      'prices': {'250g': 159, '500g': 299},
      'defaultPrice': '250g is ₹159 and 500g is ₹299',
    },
  ];

  FaqResponse getResponse(String query) {
    String q = query.toLowerCase().trim();

    // Check for review/feedback intent
    if (q.contains('review') || q.contains('feedback') || q.contains('satisfaction') || q.contains('pudichirukka')) {
      return FaqResponse(
        text: 'We value your feedback! Would you like to leave a review for Win Leaf Tea?',
        options: ['Yes, leave a review', 'No, thanks'],
        type: 'review_start',
      );
    }

    // 1. Check for SPECIFIC brand/product queries FIRST
    for (var prod in _productCatalog) {
      bool matchesBrand = prod['keywords'].any((kw) => q.contains(kw));
      if (matchesBrand) {
        String name = prod['name'];
        Map<String, int> prices = Map<String, int>.from(prod['prices']);

        if (q.contains('250g') || q.contains('250')) {
          if (prices.containsKey('250g')) {
            return FaqResponse(
              text: '$name (250g) is ₹${prices['250g']}.',
              type: 'product_price',
            );
          }
        }
        if (q.contains('500g') || q.contains('500')) {
          if (prices.containsKey('500g')) {
            return FaqResponse(
              text: '$name (500g) is ₹${prices['500g']}.',
              type: 'product_price',
            );
          }
        }
        if (q.contains('1kg') || q.contains('1 kg') || q.contains('1000g')) {
          if (prices.containsKey('1kg')) {
            return FaqResponse(
              text: '$name (1kg) is ₹${prices['1kg']}.',
              type: 'product_price',
            );
          }
        }

        // If no weight specified, return full pricing for this specific brand
        return FaqResponse(
          text: '$name prices: ${prod['defaultPrice']}.',
          type: 'product_price',
        );
      }
    }

    // 2. Check for generic "price" or "price list" query
    if (q == 'price' || q.contains('price list') || q.contains('prices')) {
      return FaqResponse(
        text: 'Win Leaf Tea Price List:\n'
            '• Classic Tea: 250g - ₹109 | 500g - ₹210\n'
            '• Premium Tea: 250g - ₹149 | 500g - ₹280\n'
            '• Hotel Blend: 1kg - ₹400 | 500g - ₹220\n\n'
            'You can view all products & order directly in the Shop section!',
        options: ['Classic Tea', 'Premium Tea', 'Hotel Blend'],
        type: 'price_list',
      );
    }

    // 3. Check for generic weight queries ONLY if no specific brand was named
    if (q == '250g' || q == '250') {
      return FaqResponse(
        text: 'Prices for 250g packs:\n'
            '• Classic Tea (250g): ₹109\n'
            '• Premium Tea (250g): ₹149\n'
            '• Masala Chai (250g): ₹129\n'
            '• Green Tea (250g): ₹159',
        type: 'weight_price',
      );
    }
    if (q == '500g' || q == '500') {
      return FaqResponse(
        text: 'Prices for 500g packs:\n'
            '• Classic Tea (500g): ₹210\n'
            '• Premium Tea (500g): ₹280\n'
            '• Hotel Blend (500g): ₹220',
        type: 'weight_price',
      );
    }
    if (q == '1kg' || q == '1 kg') {
      return FaqResponse(
        text: 'Prices for 1kg packs:\n'
            '• Hotel Blend (1kg): ₹400\n'
            '• Premium Tea (1kg): ₹520',
        type: 'weight_price',
      );
    }

    // Other FAQ queries
    if (q.contains('track')) {
      return FaqResponse(
        text: 'To track your order, go to Profile -> My Orders. You can see the status of all your recent purchases there.',
        type: 'faq',
      );
    }
    if (q.contains('delivery')) {
      return FaqResponse(
        text: 'We deliver across India! Usually, it takes 3-5 business days for your premium tea to reach your doorstep.',
        type: 'faq',
      );
    }
    if (q.contains('contact') || q.contains('support')) {
      return FaqResponse(
        text: 'You can reach us at support@winleafteas.com or click the "Talk to Human" button below to chat on WhatsApp.',
        type: 'faq',
      );
    }
    if (q.contains('winleaf') || q.contains('about') || q.contains('story')) {
      return FaqResponse(
        text: 'Win Leaf Tea is founded by Mr. Syed Mohammed, a former cricketer turned tea enthusiast, bringing pure Assam tea essence directly from the finest gardens to your home.',
        type: 'faq',
      );
    }

    // Default fallback
    return FaqResponse(
      text: "I'm sorry, I don't have information on that exact item. Would you like to talk to our support team on WhatsApp?",
      options: ['Talk to Human', 'Price List'],
      type: 'whatsapp',
    );
  }
}
