import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;

  final String _systemPrompt = """
You are the Win Leaf Tea Assistant. You are a helpful guide for Win Leaf customers.
STRICT RULE: You ONLY answer questions related to Win Leaf Tea products, the Win Leaf brand, tea brewing for Win Leaf blends, and Win Leaf customer support (like order tracking guidance).
If a user asks a common, general, or unrelated question (e.g., weather, politics, other brands, general knowledge), you must politely decline by saying:
"I am here to help you with Win Leaf Tea only. Please ask something about our products or your orders!"

Win Leaf is a premium tea brand that procures directly from the finest Assam tea gardens. They offer various blends and sizes: Classic Tea 250g (₹109), 500g (₹210), and Hotel Blend 1kg (₹400).
""";

  void init() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("Error: GEMINI_API_KEY not found in .env");
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _chatSession = _model!.startChat();
  }

  Future<String> sendMessage(String message) async {
    if (_chatSession == null) {
      init(); // Try to init if not already
      if (_chatSession == null) {
        return "I'm sorry, I'm having trouble connecting right now. Please try again later.";
      }
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? "I'm not sure how to respond to that.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
