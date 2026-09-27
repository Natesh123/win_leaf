import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../widgets/typing_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/chat_provider.dart';

class ChatWindow extends StatelessWidget {
  const ChatWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.support_agent, color: AppColors.primaryOrange, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Win Leaf Assistant',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Row(
                                children: [
                                  CircleAvatar(radius: 4, backgroundColor: Colors.green),
                                  SizedBox(width: 6),
                                  Text(
                                    'Online',
                                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Chat Messages
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView.builder(
                      controller: provider.scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.messages[index];
                        final isUser = msg['role'] == 'user';
                        final options = msg['options'] as List<String>?;

                        return TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 400),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isUser)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
                                    child: const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.primaryOrange),
                                  ),
                                if (!isUser) const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isUser ? AppColors.primaryOrange : const Color(0xFFF5F7FA),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(20),
                                            topRight: const Radius.circular(20),
                                            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                                            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg['text']!,
                                              style: TextStyle(
                                                color: isUser ? Colors.white : AppColors.textDark,
                                                fontSize: 15,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isUser && options != null && options.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: options.map((opt) => ElevatedButton(
                                              onPressed: () => provider.handleOptionSelected(opt),
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: AppColors.primaryOrange,
                                                backgroundColor: AppColors.primaryOrange.withOpacity(0.05),
                                                elevation: 0,
                                                side: BorderSide(color: AppColors.primaryOrange.withOpacity(0.2)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              ),
                                              child: Text(opt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                            )).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isUser) const SizedBox(width: 8),
                                if (isUser)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primaryGold.withOpacity(0.2),
                                    child: const Icon(Icons.person_outline, size: 18, color: AppColors.primaryGold),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: TypingIndicator(),
                  ),
                // Input Area
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: provider.controller,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: (val) => provider.sendMessage(val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: () => provider.sendMessage(provider.controller.text),
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

