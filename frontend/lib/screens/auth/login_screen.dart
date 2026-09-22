import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/local_auth_service.dart';
import '../../theme/kirana_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _authService = LocalAuthService();

  bool _isLoading = false;
  bool _showMobileLogin = false;
  bool _otpRequested = false;

  String? _generatedOtp;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildHeading(),
                  const SizedBox(height: 28),
                  _buildAuthCard(),
                  const SizedBox(height: 20),
                  _buildOfflineStatus(),
                  const SizedBox(height: 24),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: SizedBox(
        width: 150,
        height: 150,
        child: Image.asset(
          'assets/images/app_icon.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.storefront_rounded,
              size: 72,
              color: KiranaColors.primary,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        const Text(
          'WELCOME BACK',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: KiranaColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your business, your records.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: KiranaColors.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: KiranaColors.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMethodSelector(),
          const SizedBox(height: 24),
          if (_showMobileLogin) _buildMobileFlow() else _buildEmailFlow(),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMethodButton(
              label: 'EMAIL',
              icon: Icons.mail_outline_rounded,
              selected: !_showMobileLogin,
              onTap: () {
                setState(() {
                  _showMobileLogin = false;
                  _errorMessage = null;
                  _successMessage = null;
                  _otpRequested = false;
                  _generatedOtp = null;
                  _otpController.clear();
                });
              },
            ),
          ),
          Expanded(
            child: _buildMethodButton(
              label: 'MOBILE',
              icon: Icons.smartphone_rounded,
              selected: _showMobileLogin,
              onTap: () {
                setState(() {
                  _showMobileLogin = true;
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? KiranaColors.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? KiranaColors.primary
                  : KiranaColors.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: selected
                    ? KiranaColors.primary
                    : KiranaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('EMAIL ADDRESS'),
        const SizedBox(height: 7),
        _buildTextField(
          controller: _emailController,
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loginWithEmail(),
        ),
        const SizedBox(height: 18),
        _buildPrimaryButton(
          label: 'CONTINUE WITH EMAIL',
          icon: Icons.arrow_forward_rounded,
          onPressed: _isLoading ? null : _loginWithEmail,
        ),
        _buildMessages(),
      ],
    );
  }

  Widget _buildMobileFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('MOBILE NUMBER'),
        const SizedBox(height: 7),
        _buildPhoneField(),
        const SizedBox(height: 8),
        Text(
          'The verification code is generated locally on this device.',
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        if (!_otpRequested)
          _buildPrimaryButton(
            label: 'GET OFFLINE OTP',
            icon: Icons.key_rounded,
            onPressed: _isLoading ? null : _requestOtp,
          )
        else
          _buildOtpVerification(),
        _buildMessages(),
      ],
    );
  }

  Widget _buildOtpVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KiranaColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'OFFLINE VERIFICATION CODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: KiranaColors.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _generatedOtp ?? '------',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 7,
                  color: KiranaColors.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Valid for 5 minutes',
                style: TextStyle(
                  fontSize: 10,
                  color: KiranaColors.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('ENTER VERIFICATION CODE'),
        const SizedBox(height: 7),
        _buildTextField(
          controller: _otpController,
          hint: '6-digit code',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 14),
        _buildPrimaryButton(
          label: 'VERIFY & CONTINUE',
          icon: Icons.check_rounded,
          onPressed: _isLoading ? null : _verifyOtp,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isLoading ? null : _requestOtp,
          child: const Text(
            'GENERATE NEW CODE',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KiranaColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text(
              '+91',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 22,
            color: KiranaColors.outlineVariant,
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 10,
              decoration: const InputDecoration(
                hintText: '10-digit mobile number',
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        color: KiranaColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    required ValueChanged<String> onSubmitted,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KiranaColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLength: maxLength,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            icon,
            size: 19,
            color: KiranaColors.onSurfaceVariant,
          ),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 19),
        label: Text(
          _isLoading ? 'PLEASE WAIT...' : label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: KiranaColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: KiranaColors.primary.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white70,
          elevation: enabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_errorMessage == null && _successMessage == null) {
      return const SizedBox.shrink();
    }

    final isError = _errorMessage != null;
    final message = isError ? _errorMessage! : _successMessage!;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError
              ? const Color(0xFFFFE5E0)
              : KiranaColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
              color: isError
                  ? KiranaColors.secondary
                  : KiranaColors.onTertiaryContainer,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isError
                      ? KiranaColors.secondary
                      : KiranaColors.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF2E8B57),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'OFFLINE AUTHENTICATION READY',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Column(
      children: [
        Text(
          'New to Vyapaar Saathi?',
          style: TextStyle(
            fontSize: 13,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        TextButton(
          onPressed: _isLoading ? null : () => context.pushNamed('onboarding'),
          child: const Text(
            'SET UP YOUR BUSINESS PROFILE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Enter your email address.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final profile = await _authService.loginWithEmail(email);

      if (!mounted) return;

      if (profile == null) {
        _showError('Unable to create the local account.');
        return;
      }

      setState(() {
        _successMessage = 'Local account verified. Opening your dashboard...';
      });

      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;

      context.goNamed('home');
    } catch (e) {
      if (!mounted) return;
      _showError('Offline login failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();

    if (!_isValidPhone(phone)) {
      _showError('Enter a valid 10-digit Indian mobile number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final otp = await _authService.requestOfflineOtp(phone);

      if (!mounted) return;

      if (otp == null) {
        _showError('Unable to generate an offline verification code.');
        return;
      }

      setState(() {
        _generatedOtp = otp;
        _otpRequested = true;
        _successMessage =
            'Your verification code was generated locally. No SMS or internet connection is required.';
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Could not generate the verification code.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (!_isValidPhone(phone)) {
      _showError('Enter a valid 10-digit mobile number.');
      return;
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      _showError('Enter the 6-digit verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final profile = await _authService.verifyOfflineOtp(
        phoneNumber: phone,
        otp: otp,
      );

      if (!mounted) return;

      if (profile == null) {
        _showError(
          'Incorrect or expired verification code. You have a maximum of 5 attempts.',
        );
        return;
      }

      setState(() {
        _successMessage = 'Mobile number verified. Opening your dashboard...';
      });

      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;

      context.goNamed('home');
    } catch (e) {
      if (!mounted) return;
      _showError('Offline verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');

    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(normalized);
  }
}
