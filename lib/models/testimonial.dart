class Testimonial {
  final int id;
  final String name;
  final String role;
  final String comment;
  final String image;
  final int rating;

  Testimonial({
    required this.id,
    required this.name,
    required this.role,
    required this.comment,
    required this.image,
    required this.rating,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    // WooCommerce Product Review fields
    // reviewer: String
    // review: String (HTML)
    // rating: int
    // reviewer_avatar_urls: Map<String, String>

    String rawReview = json['review'] ?? '';
    // Basic HTML tag removal
    String cleanReview = rawReview.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
    String reviewerName = json['reviewer'] ?? 'Customer';

    String imageUrl = 'https://i.pravatar.cc/150';
    
    // Check if the review has an avatar from WooCommerce
    if (json['reviewer_avatar_urls'] != null && json['reviewer_avatar_urls']['96'] != null) {
      imageUrl = json['reviewer_avatar_urls']['96'];
    }
    
    // Override if it's a known VIP, to avoid gravatar/pravatar fallbacks
    String lowerName = reviewerName.toLowerCase();
    if (lowerName.contains('bharath')) {
      imageUrl = 'assets/images/bharath.jpg';
    } else if (lowerName.contains('vikranth')) {
      imageUrl = 'assets/images/vikranth.jpg';
    } else if (lowerName.contains('natarajan')) {
      imageUrl = 'assets/images/natarajan.jpg';
    } else if (lowerName.contains('vishnu')) {
      imageUrl = 'assets/images/vishnu.jpg';
    } else if (lowerName.contains('shanthnu')) {
      imageUrl = 'assets/images/shanthnu.jpg';
    } else if (lowerName.contains('karnakaran')) {
      imageUrl = 'assets/images/karnakaran.jpg';
    } else if (lowerName.contains('kalaiyarasan')) {
      imageUrl = 'assets/images/kalaiyarasan.jpg';
    } else if (lowerName.contains('jwala')) {
      imageUrl = 'assets/images/natarajan.jpg'; // Using placeholder for now
    }

    return Testimonial(
      id: json['id'] ?? 0,
      name: reviewerName,
      role: 'Valued Customer', // Default role since WC reviews don't have it
      comment: cleanReview,
      image: imageUrl,
      rating: json['rating'] ?? 5,
    );
  }

  static List<Testimonial> get fallbacks => [
        Testimonial(
            id: -1,
            name: 'Bharath',
            role: 'Actor',
            comment:
                '"A cup of tea is a cup of peace." And I recently happened to try "Winleaf" tea and got to say it was super relishing and rejuvenating. Enjoyed every sip of its refreshing flavour.',
            image: 'assets/images/bharath.jpg',
            rating: 5),
        Testimonial(
            id: -2,
            name: 'Vikranth',
            role: 'Actor',
            comment:
                'Sip into something pure and delicious with Winleaf premium tea dust! Made from only the finest tea leaves. Once you try it, you\'ll never want to settle for anything less!',
            image: 'assets/images/vikranth.jpg',
            rating: 5),
        Testimonial(
            id: -3,
            name: 'T. Natarajan',
            role: 'Cricketer',
            comment:
                'Recently tried out Winleaf pure dust tea and it tastes so good, the strength and maltiness is perfectly blended. I would say it\'s better than most of the leading brands in the market.',
            image: 'assets/images/natarajan.jpg',
            rating: 5),
        Testimonial(
            id: -4,
            name: 'Vishnu Vishal',
            role: 'Actor',
            comment:
                'Winleaf pure dust tea tastes so good, it\'s better than most of the leading brands in the market and the price is 30% lesser.',
            image: 'assets/images/vishnu.jpg',
            rating: 5),
        Testimonial(
            id: -5,
            name: 'Shanthnu',
            role: 'Actor',
            comment:
                'Recently tried out Winleaf pure dust tea and it tastes so good. I\'m sure you\'ll enjoy it too.',
            image: 'assets/images/shanthnu.jpg',
            rating: 5),
        Testimonial(
            id: -6,
            name: 'Karnakaran',
            role: 'Actor',
            comment:
                'Recently tried Winleaf. The tea leaves were whole and visually appealing, and the aroma was light and delicate.',
            image: 'assets/images/karnakaran.jpg',
            rating: 5),
        Testimonial(
            id: -7,
            name: 'Kalaiyarasan',
            role: 'Actor',
            comment:
                'The Winleaf is a aromatic masterpiece. The taste is a true reflection of its organic origins, making it a clean and refreshing choice for tea lovers.',
            image: 'assets/images/kalaiyarasan.jpg',
            rating: 5),
        Testimonial(
            id: -8,
            name: 'Jwala Gutta',
            role: 'Tennis Player',
            comment:
                'The pure flavor is perfect for soothing digestion. The tea bags are individually wrapped, maintaining freshness. This is my go-to after a heavy meal.',
            image: 'assets/images/natarajan.jpg', // Fallback since Jwala's image wasn't found, using a valid URL to prevent crash
            rating: 5),
      ];
}
