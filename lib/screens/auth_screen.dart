import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/home_provider.dart';
import '../providers/rewards_provider.dart';
import '../providers/order_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/cart_provider.dart';
import 'widgets/gradient_background.dart';
import '../core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/phone_login_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const _AuthScreenBody(),
    );
  }
}

class _AuthScreenBody extends StatefulWidget {
  const _AuthScreenBody();

  @override
  State<_AuthScreenBody> createState() => _AuthScreenBodyState();
}

class _AuthScreenBodyState extends State<_AuthScreenBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _verificationFormKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _forgotPasswordFormKey = GlobalKey<FormState>();
  final _forgotEmailController = TextEditingController();
  final _forgotOtpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupOtpController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignupOtpSent = false;
  String? _signupVerificationId;

  // Verification & Reset states
  bool _isPhoneLogin = false;
  bool _isVerifying = false;
  bool _isForgotPassword = false;
  bool _otpSent = false;
  String _verificationToken = '';
  String _verificationNonce = '';
  List<String> _sessionCookies = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _updateProvidersAfterAuth() {
    if (!mounted) return;
    try { Provider.of<ProfileProvider>(context, listen: false).checkStatus(); } catch(e){}
    try { Provider.of<HomeProvider>(context, listen: false).fetchAll(); } catch(e){}
    try { Provider.of<RewardsProvider>(context, listen: false).fetchData(); } catch(e){}
    try { Provider.of<OrderProvider>(context, listen: false).fetchOrders(); } catch(e){}
    try { Provider.of<SubscriptionsProvider>(context, listen: false).fetchSubscriptions(); } catch(e){}
    try { Provider.of<CartProvider>(context, listen: false).loadCartFromServer(); } catch(e){}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    _forgotEmailController.dispose();
    _forgotOtpController.dispose();
    _newPasswordController.dispose();
    _signupPhoneController.dispose();
    _signupOtpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendForgotPasswordOtp(AuthProvider authProvider) async {
    if (_forgotEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    final result = await authProvider.sendForgotPasswordOtp(_forgotEmailController.text.trim());
    if (result['success'] == true) {
      setState(() {
        _otpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP code sent to ${_forgotEmailController.text.trim()}!'),
            backgroundColor: AppColors.primaryOrange,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send OTP'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyOtpAndLogin(AuthProvider authProvider) async {
    if (_forgotOtpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code.')),
      );
      return;
    }

    final result = await authProvider.verifyOtpAndLogin(
      _forgotEmailController.text.trim(),
      _forgotOtpController.text.trim(),
      _newPasswordController.text.trim(),
    );

    if (result['success'] == true) {
      if (mounted) {
        _updateProvidersAfterAuth();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully! Logged in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid OTP code or login failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (_loginFormKey.currentState!.validate()) {
      final result = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        if (mounted) {
          _updateProvidersAfterAuth();
          Navigator.pop(context, true); // Direct ah home page poga (pop the auth screen)
        }
      } else {
        if (mounted) {
          String errorMsg = result['message'] ?? 'Login failed';
          
          // If the error suggests the user does not exist, ask them to sign up
          if (errorMsg.toLowerCase().contains('unknown') || 
              errorMsg.toLowerCase().contains('invalid username') || 
              errorMsg.toLowerCase().contains('invalid email') ||
              errorMsg.toLowerCase().contains('not found')) {
            errorMsg = 'Account not found. Please sign up first!';
            // Switch to signup tab
            _tabController.animateTo(1);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    }
  }

  bool _isSignupLoading = false;

  String _getFirebaseErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-phone-number':
          return 'Please enter a valid 10-digit mobile number.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a few minutes and try again.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'invalid-verification-code':
          return 'The OTP you entered is incorrect. Please check and try again.';
        case 'session-expired':
          return 'The OTP has expired. Please request a new one.';
        default:
          return 'Error: ${e.message}';
      }
    }
    return 'An unexpected error occurred: ${e.toString()}';
  }

  Future<bool> _checkIfAccountExists(AuthProvider authProvider, String identifier) async {
    final result = await authProvider.login(identifier, 'WinLeaf_Fake_Password_Check_123!');
    if (result['success']) return true;
    
    final msg = (result['message'] ?? '').toLowerCase();
    if (msg.contains('unknown') || 
        msg.contains('invalid username') || 
        msg.contains('invalid email') ||
        msg.contains('not found') ||
        msg.contains('incorrect username')) {
      return false;
    }
    return true;
  }

  Future<void> _handleSignupFlow(AuthProvider authProvider) async {
    if (!_signupFormKey.currentState!.validate()) return;
    
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    String phone = _signupPhoneController.text.trim();

    if (phone.length == 10 && !phone.startsWith('+')) {
      phone = '+91$phone';
    }

    if (!_isSignupOtpSent) {
      // Step 1: Send OTP
      
      setState(() => _isSignupLoading = true);
      
      // Check if account already exists
      bool exists = await _checkIfAccountExists(authProvider, email);
      if (!exists) {
        // Try checking phone number without +91
        exists = await _checkIfAccountExists(authProvider, _signupPhoneController.text.trim());
      }
      
      if (exists) {
        setState(() => _isSignupLoading = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Account Exists'),
              content: const Text('This Mobile Number or Email is already registered.\n\nPlease continue with login.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    _tabController.animateTo(0); // Go to login tab
                  },
                  child: const Text('Login Now', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          timeout: const Duration(seconds: 120),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _completeSignupWithCredential(credential, authProvider, username, email, password, phone);
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() => _isSignupLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_getFirebaseErrorMessage(e))),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _isSignupLoading = false;
              _signupVerificationId = verificationId;
              _isSignupOtpSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent to your phone!')),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _signupVerificationId = verificationId;
          },
        );
      } catch (e) {
        setState(() => _isSignupLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_getFirebaseErrorMessage(e))));
      }
    } else {
      // Step 2: Verify OTP
      final otp = _signupOtpController.text.trim();
      setState(() => _isSignupLoading = true);
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _signupVerificationId!,
          smsCode: otp,
        );
        await _completeSignupWithCredential(credential, authProvider, username, email, password, phone);
      } catch (e) {
        setState(() => _isSignupLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getFirebaseErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _completeSignupWithCredential(PhoneAuthCredential credential, AuthProvider authProvider, String username, String email, String password, String phone) async {
    try {
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCred.user != null) {
        // Link WP identity to Firebase Profile for later login reference!
        await userCred.user!.updateDisplayName(username);
        
        setState(() => _isSignupLoading = false);
        
        // Proceed with WP Registration
        await _handleSignup(authProvider, phone);
      }
    } catch (e) {
      // If the credential expired because they pressed verify again after a WP error,
      // but they are already authenticated in Firebase with this number, we can bypass!
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && (currentUser.phoneNumber == phone || currentUser.phoneNumber == '+91$phone')) {
        setState(() => _isSignupLoading = false);
        await _handleSignup(authProvider, phone);
        return;
      }

      setState(() => _isSignupLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getFirebaseErrorMessage(e))),
      );
    }
  }

  Future<void> _handleSignup(AuthProvider authProvider, String phone) async {
    if (_signupFormKey.currentState!.validate()) {
      final result = await authProvider.signup(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        phone,
      );

      if (result['success']) {
        if (result['requireVerification'] == true) {
          setState(() {
            _isVerifying = true;
            _verificationToken = result['token'] ?? '';
            _verificationNonce = result['nonce'] ?? '';
            _sessionCookies = List<String>.from(result['cookies'] ?? []);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification code sent to your email!'),
                backgroundColor: AppColors.primaryOrange,
              ),
            );
          }
        } else {
          if (mounted) {
            _updateProvidersAfterAuth();
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: result['alreadyExists'] == true ? AppColors.primaryOrange : Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
          if (result['alreadyExists'] == true) {
            _tabController.animateTo(0); // Go to login tab
          }
        }
      }
    }
  }

  Future<void> _handleVerify(AuthProvider authProvider) async {
    if (_verificationFormKey.currentState!.validate()) {
      final result = await authProvider.verifySignup(
        _verificationToken,
        _verificationNonce,
        _verificationCodeController.text.trim(),
        _sessionCookies,
        _usernameController.text,
        _passwordController.text,
      );

      if (result['success']) {
        if (mounted) {
          if (result['loginFailed'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Account verified! Please login manually. (${result['message']})'),
                backgroundColor: AppColors.primaryOrange,
                duration: const Duration(seconds: 8),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration completed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _updateProvidersAfterAuth();
          }
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Verification failed'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResend(AuthProvider authProvider) async {
    final result = await authProvider.resendVerificationCode(
      _verificationToken,
      _verificationNonce,
      _sessionCookies,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Resend failed'),
          backgroundColor: result['success'] ? AppColors.primaryOrange : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: CloseButton(
                color: AppColors.textDark,
                onPressed: () {
                  if (_isForgotPassword) {
                    setState(() {
                      _isForgotPassword = false;
                      _otpSent = false;
                    });
                  } else if (_isVerifying) {
                    setState(() => _isVerifying = false);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              bottom: (_isVerifying || _isForgotPassword)
                  ? null
                  : TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryOrange,
                      unselectedLabelColor: AppColors.textGrey,
                      indicatorColor: AppColors.primaryOrange,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'LOGIN'),
                        Tab(text: 'SIGNUP'),
                      ],
                    ),
            ),
            body: _isPhoneLogin
                ? PhoneLoginWidget(onBack: () => setState(() => _isPhoneLogin = false))
                : _isForgotPassword
                    ? _buildForgotPasswordForm(authProvider)
                    : _isVerifying
                        ? _buildVerificationForm(authProvider)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLoginForm(authProvider),
                              _buildSignupForm(authProvider),
                            ],
                          ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildLogo(),
            const SizedBox(height: 40),
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                labelStyle: TextStyle(color: AppColors.textGrey),
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textGrey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
              ),
              validator: (v) => v!.isEmpty ? 'Enter your username' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: AppColors.textGrey),
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textGrey),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textGrey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
              ),
              validator: (v) => v!.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isForgotPassword = true;
                    _otpSent = false;
                    _forgotEmailController.text = _usernameController.text;
                  });
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : () => _handleLogin(authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: authProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.cardGrey)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: AppColors.textGrey)),
                ),
                Expanded(child: Divider(color: AppColors.cardGrey)),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isPhoneLogin = true;
                });
              },
              icon: const Icon(Icons.phone_android, color: AppColors.textDark),
              label: const Text('Continue with Phone', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.cardGrey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signupFormKey,
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildLogo(),
            const SizedBox(height: 40),
            TextFormField(
              controller: _usernameController,
              enabled: !_isSignupOtpSent,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Username / Full Name',
                labelStyle: TextStyle(color: AppColors.textGrey),
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textGrey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
              ),
              validator: (v) => v!.isEmpty ? 'Enter a username' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              enabled: !_isSignupOtpSent,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(color: AppColors.textGrey),
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.textGrey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
              ),
              validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !_isSignupOtpSent,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: AppColors.textGrey),
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textGrey),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textGrey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
              ),
              validator: (v) => v!.length < 6 ? 'Password too short' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isSignupOtpSent ? _signupOtpController : _signupPhoneController,
              keyboardType: _isSignupOtpSent ? TextInputType.number : TextInputType.phone,
              maxLength: _isSignupOtpSent ? 6 : 10,
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                counterText: "",
                labelText: _isSignupOtpSent ? 'Enter OTP Code' : 'Mobile Number',
                prefixText: _isSignupOtpSent ? null : '+91 ',
                prefixStyle: const TextStyle(color: AppColors.textDark, fontSize: 16),
                labelStyle: const TextStyle(color: AppColors.textGrey),
                prefixIcon: Icon(_isSignupOtpSent ? Icons.security : Icons.phone, color: AppColors.textGrey),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
              ),
              onChanged: (value) {
                if (_isSignupOtpSent && value.length == 6) {
                  _handleSignupFlow(authProvider);
                }
              },
              validator: (v) {
                if (_isSignupOtpSent) {
                  return v!.isEmpty ? 'Enter the OTP' : null;
                } else {
                  return v!.length < 10 ? 'Enter a valid 10-digit number' : null;
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (authProvider.isLoading || _isSignupLoading) ? null : () => _handleSignupFlow(authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: (authProvider.isLoading || _isSignupLoading)
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isSignupOtpSent ? 'Verify & Create Account' : 'Send OTP', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (_isSignupOtpSent) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isSignupOtpSent = false),
                child: const Text('Edit Details / Resend OTP', style: TextStyle(color: AppColors.textGrey)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _verificationFormKey,
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildLogo(),
            const SizedBox(height: 40),
            const Text(
              'Verify Your Registration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please enter the email verification code sent to:\n${_emailController.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _verificationCodeController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                labelStyle: TextStyle(color: AppColors.textGrey),
                prefixIcon: Icon(Icons.security, color: AppColors.textGrey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
              ),
              validator: (v) => v!.isEmpty ? 'Enter the code' : null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : () => _handleVerify(authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: authProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify and Register', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Didn't receive the code?",
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: authProvider.isLoading ? null : () => _handleResend(authProvider),
              child: const Text(
                'Resend Email Code',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isVerifying = false),
              child: const Text(
                'Back to Signup',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _forgotPasswordFormKey,
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildLogo(),
            const SizedBox(height: 30),
            Text(
              _otpSent ? 'Enter OTP Code' : 'Reset Password',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _otpSent
                  ? 'Enter the email OTP sent to:\n${_forgotEmailController.text}'
                  : 'Enter your email address to receive an OTP code for password reset.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _forgotEmailController,
              enabled: !_otpSent,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Email Address / Username',
                labelStyle: TextStyle(color: AppColors.textGrey),
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.textGrey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
              ),
              validator: (v) => v!.isEmpty ? 'Enter your email' : null,
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _forgotOtpController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textDark),
                decoration: const InputDecoration(
                  labelText: 'Enter OTP Code',
                  labelStyle: TextStyle(color: AppColors.textGrey),
                  prefixIcon: Icon(Icons.security, color: AppColors.textGrey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
                ),
                validator: (v) => v!.isEmpty ? 'Enter the OTP code' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: 'New Password (Optional)',
                  labelStyle: const TextStyle(color: AppColors.textGrey),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textGrey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        if (!_otpSent) {
                          _handleSendForgotPasswordOtp(authProvider);
                        } else {
                          _handleVerifyOtpAndLogin(authProvider);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _otpSent ? 'Verify OTP & Login' : 'Send OTP',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_otpSent) ...[
              TextButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () => _handleSendForgotPasswordOtp(authProvider),
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            TextButton(
              onPressed: () {
                setState(() {
                  _isForgotPassword = false;
                  _otpSent = false;
                });
              },
              child: const Text(
                'Back to Login',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        image: const DecorationImage(
          image: AssetImage('assets/images/winleaf logo.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}
