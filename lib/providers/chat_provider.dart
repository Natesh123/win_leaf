import 'package:flutter/material.dart';
import '../../services/faq_service.dart';
import '../../services/url_launcher_service.dart';

class ChatProvider extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final UrlLauncherService _launcherService = UrlLauncherService();
  final FaqService _faqService = FaqService();

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'bot',
      'text': 'Hello! I am your Win Leaf Assistant. How can I help you today?',
      'options': ['Price List', 'Track Order', 'Win Leaf Story', 'Submit Review'],
      'timestamp': DateTime.now(),
    }
  ];

  bool _isLoading = false;
  String _currentFlow = 'idle';
  int? _selectedRating;
  String? _selectedProduct;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add({
      'role': 'user',
      'text': text,
      'timestamp': DateTime.now(),
    });
    controller.clear();
    _isLoading = true;
    notifyListeners();
    scrollToBottom();

    // Handle Review Flow Logic
    if (_currentFlow == 'awaiting_rating') {
      _selectedRating = int.tryParse(text.split(' ')[0]);
      await Future.delayed(const Duration(milliseconds: 1000));
      _currentFlow = 'awaiting_product';
      _messages.add({
        'role': 'bot',
        'text': 'Which product did you use?',
        'options': ['Classic Tea (250g)', 'Classic Tea (500g)', 'Hotel Blend (1kg)', 'Others'],
        'timestamp': DateTime.now(),
      });
      _isLoading = false;
      notifyListeners();
      scrollToBottom();
      return;
    }

    if (_currentFlow == 'awaiting_product') {
      _selectedProduct = text;
      await Future.delayed(const Duration(milliseconds: 1000));
      _currentFlow = 'awaiting_comment';
      _messages.add({
        'role': 'bot',
        'text': 'Great! Any specific feedback or comments you would like to share about $_selectedProduct?',
        'timestamp': DateTime.now(),
      });
      _isLoading = false;
      notifyListeners();
      scrollToBottom();
      return;
    }

    if (_currentFlow == 'awaiting_comment') {
      final reviewText = text;
      await Future.delayed(const Duration(milliseconds: 1000));
      _currentFlow = 'idle';
      _messages.add({
        'role': 'bot',
        'text': 'Thank you so much! I have prepared your review. Click below to send it to our team on WhatsApp.',
        'options': ['Send Review to WhatsApp'],
        'metadata': {
          'stars': _selectedRating,
          'product': _selectedProduct,
          'comment': reviewText
        },
        'timestamp': DateTime.now(),
      });
      _isLoading = false;
      notifyListeners();
      scrollToBottom();
      return;
    }

    // Default FAQ Handling
    final response = _faqService.getResponse(text);
    await Future.delayed(const Duration(milliseconds: 1000));

    _messages.add({
      'role': 'bot',
      'text': response.text,
      'options': response.options,
      'timestamp': DateTime.now(),
    });

    if (text == 'Submit Review' || response.type == 'review_start') {
      _currentFlow = 'awaiting_rating';
      _messages.last['text'] = 'How would you rate Win Leaf Tea? (1 to 5 Stars)';
      _messages.last['options'] = ['1 Star', '2 Stars', '3 Stars', '4 Stars', '5 Stars'];
    }

    _isLoading = false;
    notifyListeners();
    scrollToBottom();
  }

  void handleOptionSelected(String option) {
    if (option == 'Talk to Human') {
      _launcherService.launchWhatsApp(message: "Hello Win Leaf, I need support with my order.");
    } else if (option == 'Send Review to WhatsApp') {
      final lastMsg = _messages.last;
      final stars = lastMsg['metadata']?['stars'] ?? 5;
      final product = lastMsg['metadata']?['product'] ?? "Not specified";
      final comment = lastMsg['metadata']?['comment'] ?? "";
      _launcherService.launchWhatsApp(
        message: "Win Leaf Review:\nRating: $stars/5 Stars\nProduct: $product\nComment: $comment",
      );
    } else if (option == 'Price List') {
      sendMessage("price");
    } else if (option == 'Track Order') {
      sendMessage("track");
    } else if (option == 'Win Leaf Story') {
      sendMessage("about");
    } else {
      sendMessage(option);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
