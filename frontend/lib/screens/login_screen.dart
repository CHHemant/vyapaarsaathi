// frontend/lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/kirana_colors.dart';
import '../widgets/rupee_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // App Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: KiranaColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              const Text(
                'VyapaarSaathi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: KiranaColors.darkBrown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Financial Partner',
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 16,
                  color: KiranaColors.darkBrown.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              // Phone Number Field
              if (!_isOtpSent) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '9876543210',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (value.length != 10) {
                            return 'Enter valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      RupeeButton(
                        label: 'Send OTP',
                        icon: Icons.send,
                        showRupeePrefix: false,
                        fullWidth: true,
                        onPressed: _sendOtp,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // OTP Field
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'OTP',
                          hintText: 'Enter 4-digit OTP',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.length != 4) {
                            return 'Enter 4-digit OTP';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      RupeeButton(
                        label: 'Login',
                        icon: Icons.login,
                        showRupeePrefix: false,
                        fullWidth: true,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() => _isOtpSent = false);
                        },
                        child: const Text('Change Number'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Demo Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KiranaColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KiranaColors.info.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: KiranaColors.info,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Demo Mode: Enter any 10-digit number and any 4-digit OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: KiranaColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isOtpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent! Use any 4 digits to login')),
      );
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authService = ref.read(authServiceProvider);
      final success = await authService.login(
        phoneNumber: _phoneController.text,
        otp: _otpController.text,
      );

      if (success && context.mounted) {
        context.goNamed('home');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Try again.')),
        );
      }
    }
  }
}