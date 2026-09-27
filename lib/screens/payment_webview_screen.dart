import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    this.title = 'Payment',
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  bool _isGatewayReached = false;
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            
            // If the URL is not a standard web link, it must be an external app deep link
            // (e.g., upi://, intent://, phonepe://, gpay://, paytm://, whatsapp://)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
                
              debugPrint('WEBVIEW: Opening external app link -> $url');
              
              try {
                String finalUrl = url;
                
                // url_launcher sometimes fails to parse raw Android intent:// strings.
                // We extract the scheme inside the intent (e.g., scheme=upi) and rewrite the URL.
                if (url.startsWith('intent://')) {
                  final schemeMatch = RegExp(r'scheme=([^;]+)').firstMatch(url);
                  if (schemeMatch != null) {
                    final scheme = schemeMatch.group(1);
                    // Replace 'intent://' with 'scheme://' and strip the #Intent... part
                    final baseUrl = url.replaceFirst('intent://', '$scheme://').split('#Intent').first;
                    finalUrl = baseUrl;
                    debugPrint('WEBVIEW: Rewrote intent:// to -> $finalUrl');
                  }
                }
                
                final uri = Uri.parse(finalUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('WEBVIEW: Could not launch external app for $url: $e');
              }
              
              // We ALWAYS prevent the WebView from loading non-http links, 
              // which completely stops the ERR_UNKNOWN_URL_SCHEME error!
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            debugPrint('WEBVIEW: [STARTED] -> $url');

            // 1. Intercept redirects to the account/login page
            if ((url.contains('/my-account/') || url.contains('/login/')) && 
                !url.contains('view-order') && 
                !url.contains('order-pay')) {
              
              debugPrint('WEBVIEW: Intercepting Login/Account URL.');
              
              final uri = Uri.parse(url);
              String? response = uri.queryParameters['phonepe_response'];
              
              if (response == null && uri.queryParameters['redirect_to'] != null) {
                try {
                  final redirectTo = Uri.parse(Uri.decodeComponent(uri.queryParameters['redirect_to']!));
                  response = redirectTo.queryParameters['phonepe_response'];
                } catch (_) {}
              }

              if (response != null) {
                String decoded = Uri.decodeComponent(response).replaceAll('+', ' ');
                Navigator.pop(context, decoded);
                return;
              } else {
                Navigator.pop(context, "Security Block: Website requires login. Staying native.");
                return;
              }
            }

            // 2. Direct interception for order result pages
            if (url.contains('phonepe_response=')) {
              final uri = Uri.parse(url);
              String? response = uri.queryParameters['phonepe_response'];
              if (response != null) {
                String decoded = Uri.decodeComponent(response).replaceAll('+', ' ');
                Navigator.pop(context, decoded);
                return;
              }
            }

            setState(() {
              _isLoading = true;
              if (!url.contains('winleafteas.com')) _isGatewayReached = true;
            });
          },
          onPageFinished: (String url) async {
            debugPrint('WEBVIEW: [FINISHED] -> $url');
            
            // Log page title to see if it's the Login page
            final String? title = await _controller.getTitle();
            debugPrint('WEBVIEW: Page Title -> $title');

            setState(() {
              _isLoading = false;
              if (!url.contains('order-pay') && !url.contains('login') && !url.contains('my-account')) {
                _isGatewayReached = true;
              }
            });
            
            // If the title is "Login" or similar, we are stuck.
            if (title != null && (title.toLowerCase().contains('login') || title.toLowerCase().contains('my account'))) {
               debugPrint('WEBVIEW: Stuck on Login page (Title detected).');
               // But we wait a second to see if it redirects again.
            }

            // Hide website header, footer, etc.
            _controller.runJavaScript("""
              var style = document.createElement('style');
              style.innerHTML = `
                .elementor-location-header, .elementor-location-footer, 
                #mwb-cpr-drag, .joinchat, .fuse-social-icons, 
                .elementor-menu-cart__wrapper, .onesignal-slidedown-container { display: none !important; }
              `;
              document.head.appendChild(style);
            """);

            // NEW: Run a script to detect if the page is actually a login form
            _controller.runJavaScript("""
              if (document.body.innerText.includes('Please log in to your account') || 
                  document.body.innerText.includes('Username or email') ||
                  document.querySelector('form.login')) {
                LoginDetector.postMessage('login_detected');
              }
            """);

            if (url.contains('order-received') || url.contains('checkout/thank-you')) {
              _showSuccessAndClose(url);
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'LoginDetector',
        onMessageReceived: (message) {
          if (message.message == 'login_detected') {
            debugPrint('WEBVIEW: Auto-closing because login form was detected on page.');
            Navigator.pop(context, "Security Block: Website requires login. Staying native.");
          }
        },
      )
      ..loadRequest(Uri.parse(widget.url));
      
    // Global safety timeout
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_isGatewayReached) {
        setState(() {
          _isGatewayReached = true;
        });
      }
    });
  }

  void _showSuccessAndClose(String url) {
    String transactionId = '';
    // Extract Order ID from WooCommerce order-received URL (e.g. /order-received/1234/)
    final RegExp orderIdRegex = RegExp(r'order-received\/(\d+)');
    final match = orderIdRegex.firstMatch(url);
    if (match != null) {
      transactionId = match.group(1) ?? '';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PhonePe Payment Solutions: Your payment is successful. Merchant Transaction ID is $transactionId'), 
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // If we reach the gateway, show it. Otherwise stay hidden behind the loader.
          Opacity(
            opacity: _isGatewayReached ? 1.0 : 0.0,
            child: WebViewWidget(controller: _controller),
          ),
          
          if (!_isGatewayReached)
            Container(
              color: AppColors.backgroundLight,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Securely connecting to payment gateway...',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait a moment',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
