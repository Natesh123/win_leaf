import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class UrlLauncherService {
  static const String whatsappNumber = "+919884078773";

  /// Opens WhatsApp with a pre-filled message
  Future<void> launchWhatsApp({String message = "Hello Win Leaf Tea! I'd like to know more about your products."}) async {
    final String url = Platform.isAndroid
        ? "https://wa.me/$whatsappNumber/?text=${Uri.encodeComponent(message)}"
        : "https://api.whatsapp.com/send?phone=$whatsappNumber&text=${Uri.encodeComponent(message)}";

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Launches a general URL
  Future<void> launchGeneralUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }
}
