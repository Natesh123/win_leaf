import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_window.dart';
import '../../core/app_colors.dart';

import 'package:url_launcher/url_launcher.dart';

class FloatingChatBot extends StatelessWidget {
  const FloatingChatBot({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'whatsapp_fab',
          backgroundColor: Colors.green,
          child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 30),
          onPressed: () async {
            final Uri url = Uri.parse('https://wa.link/32vvj1');
            if (!await launchUrl(url)) {
              debugPrint('Could not launch \$url');
            }
          },
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'chatbot_fab',
          backgroundColor: AppColors.primaryOrange,
          child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const ChatWindow(),
            );
          },
        ),
      ],
    );
  }
}
