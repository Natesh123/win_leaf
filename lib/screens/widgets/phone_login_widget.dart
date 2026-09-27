import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';


class PhoneLoginWidget extends StatefulWidget {
  final VoidCallback onBack;

  const PhoneLoginWidget({super.key, required this.onBack});

  @override
  State<PhoneLoginWidget> createState() => _PhoneLoginWidgetState();
}

class _PhoneLoginWidgetState extends State<PhoneLoginWidget> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;

  String _getErrorMessage(dynamic e) {
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
        case 'quota-exceeded':
          return 'SMS quota exceeded. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> _sendOtp() async {
    String phone = _phoneController.text.trim();
    
    // Automatically add +91 if the user just entered a 10 digit number
    if (phone.length == 10 && !phone.startsWith('+')) {
      phone = '+91$phone';
    }

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit Indian phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_getErrorMessage(e))),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(e))),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(e))),
      );
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        String phone = _phoneController.text.trim();
        final authService = AuthService();
        bool exists = await authService.checkPhoneExists(phone);
        
        if (!exists) {
          await FirebaseAuth.instance.signOut();
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account not found! Please Sign Up first.'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        await _handleSuccessfulLogin(user);
      }
    } catch (e) {
      // If the credential expired because they pressed verify again,
      // but they are already authenticated in Firebase with this number, we can bypass!
      final currentUser = FirebaseAuth.instance.currentUser;
      String phone = _phoneController.text.trim();
      if (phone.length == 10 && !phone.startsWith('+')) phone = '+91$phone';
      
      if (currentUser != null && (currentUser.phoneNumber == phone || currentUser.phoneNumber == '+91$phone')) {
        final authService = AuthService();
        bool exists = await authService.checkPhoneExists(phone);
        if (!exists) {
          await FirebaseAuth.instance.signOut();
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account not found! Please Sign Up first.'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        await _handleSuccessfulLogin(currentUser);
        return;
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _handleSuccessfulLogin(User user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use the real Name and Email linked during Signup!
    final displayName = user.displayName ?? user.phoneNumber ?? 'User';
    final email = user.email ?? '${user.phoneNumber}@winleaf-tea.firebaseapp.com';

    await prefs.setString('jwt_token', 'otp_session_${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setString('user_display_name', displayName);
    await prefs.setString('user_email', email);
    
    if (mounted) {
      Provider.of<ProfileProvider>(context, listen: false).checkStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone verified! Logged in successfully.')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildLogo(),
          const SizedBox(height: 30),
          Text(
            _otpSent ? 'Enter SMS Code' : 'Phone Login',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _otpSent
                ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                : 'Enter your 10-digit mobile number to receive an OTP',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _otpSent ? _otpController : _phoneController,
            keyboardType: _otpSent ? TextInputType.number : TextInputType.phone,
            maxLength: _otpSent ? 6 : 10,
            style: const TextStyle(color: AppColors.textDark),
            decoration: InputDecoration(
              counterText: "",
              labelText: _otpSent ? 'Enter OTP Code' : 'Mobile Number',
              prefixText: _otpSent ? null : '+91 ',
              prefixStyle: const TextStyle(color: AppColors.textDark, fontSize: 16),
              labelStyle: const TextStyle(color: AppColors.textGrey),
              prefixIcon: Icon(_otpSent ? Icons.security : Icons.phone, color: AppColors.textGrey),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardGrey)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryOrange)),
            ),
            onChanged: (value) {
              if (_otpSent && value.length == 6) {
                _verifyOtp();
              }
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (!_otpSent) {
                        _sendOtp();
                      } else {
                        _verifyOtp();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _otpSent ? 'Verify OTP' : 'Send SMS',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onBack,
            child: const Text(
              'Back to Email Login',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
        ],
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
