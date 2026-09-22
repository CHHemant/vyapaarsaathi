import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../services/local_auth_service.dart';
import '../../theme/kirana_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final _authService = LocalAuthService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final user = await _authService.getCurrentUser();

      if (!mounted) return;

      _currentUser = user;

      if (user != null) {
        _storeNameController.text =
            user.storeName == 'My Store' ? '' : user.storeName;
        _ownerNameController.text =
            user.ownerName == 'Owner' ? '' : user.ownerName;
        _phoneController.text = user.phoneNumber;
        _emailController.text = user.email ?? '';
        _addressController.text = user.address ?? '';
        _cityController.text = user.city ?? '';
        _stateController.text = user.state ?? '';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your local profile.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: KiranaColors.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 28),
                        _buildHeading(),
                        const SizedBox(height: 24),
                        _buildFormCard(),
                        const SizedBox(height: 20),
                        _buildOfflineNotice(),
                        const SizedBox(height: 24),
                        _buildBackButton(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: _isSaving ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: KiranaColors.primary,
          tooltip: 'Back',
        ),
        const Spacer(),
        SizedBox(
          width: 54,
          height: 54,
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.storefront_rounded,
                color: KiranaColors.primary,
                size: 32,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SET UP YOUR BUSINESS',
          style: TextStyle(
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: KiranaColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Create your local business profile.',
          style: TextStyle(
            fontSize: 14,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your information stays on this device until you choose to sync it.',
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
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
          _buildSectionLabel('BUSINESS DETAILS'),
          const SizedBox(height: 16),
          _buildField(
            controller: _storeNameController,
            label: 'BUSINESS / STORE NAME',
            hint: 'e.g. Sri Lakshmi Stores',
            icon: Icons.storefront_rounded,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _ownerNameController,
            label: 'OWNER NAME',
            hint: 'Your full name',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 22),
          _buildSectionLabel('CONTACT'),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildField(
            controller: _emailController,
            label: 'EMAIL ADDRESS',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),
          _buildSectionLabel('LOCATION'),
          const SizedBox(height: 16),
          _buildField(
            controller: _addressController,
            label: 'ADDRESS',
            hint: 'Shop or business address',
            icon: Icons.location_on_outlined,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _cityController,
                  label: 'CITY',
                  hint: 'City',
                  icon: Icons.location_city_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _stateController,
                  label: 'STATE',
                  hint: 'State',
                  icon: Icons.map_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) _buildError(),
          if (_errorMessage != null) const SizedBox(height: 14),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: KiranaColors.secondary,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 7),
        Container(
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
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  top: maxLines > 1 ? 4 : 0,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: KiranaColors.onSurfaceVariant,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'MOBILE NUMBER',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 7),
        Container(
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: KiranaColors.secondary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: KiranaColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProfile,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.arrow_forward_rounded,
                size: 19,
              ),
        label: Text(
          _isSaving ? 'SAVING...' : 'SAVE & CONTINUE',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: KiranaColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: KiranaColors.primary.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: KiranaColors.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 17,
              color: KiranaColors.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'OFFLINE PROFILE SETUP — No internet connection is required.',
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton(
      onPressed: _isSaving ? null : () => context.goNamed('login'),
      child: const Text(
        'BACK TO LOGIN',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final storeName = _storeNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final phone = _normalizePhone(_phoneController.text);
    final email = _emailController.text.trim().toLowerCase();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();

    if (storeName.isEmpty) {
      _showError('Enter your business or store name.');
      return;
    }

    if (ownerName.isEmpty) {
      _showError('Enter the owner name.');
      return;
    }

    if (!_isValidPhone(phone)) {
      _showError('Enter a valid 10-digit Indian mobile number.');
      return;
    }

    if (email.isNotEmpty && !_isValidEmail(email)) {
      _showError('Enter a valid email address or leave it empty.');
      return;
    }

    if (city.isEmpty) {
      _showError('Enter your city.');
      return;
    }

    if (state.isEmpty) {
      _showError('Enter your state.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final existingUser = _currentUser ?? await _authService.getCurrentUser();

      final profile = existingUser != null
          ? existingUser.copyWith(
              storeName: storeName,
              ownerName: ownerName,
              phoneNumber: phone,
              email: email.isEmpty ? null : email,
              address: address.isEmpty ? null : address,
              city: city,
              state: state,
              isActive: true,
            )
          : UserProfile(
              id: 'account_${DateTime.now().microsecondsSinceEpoch}',
              storeName: storeName,
              ownerName: ownerName,
              phoneNumber: phone,
              email: email.isEmpty ? null : email,
              address: address.isEmpty ? null : address,
              city: city,
              state: state,
              createdAt: DateTime.now(),
              isActive: true,
            );

      await _authService.updateProfile(profile);

      if (existingUser == null) {
        await _authService.setCurrentAccount(profile.id);
      }

      if (!mounted) return;

      context.goNamed('home');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage =
            'Could not save your profile locally. Please try again.';
      });
    }
  }

  String _normalizePhone(String phone) {
    var value = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (value.startsWith('+91')) {
      value = value.substring(3);
    } else if (value.startsWith('91') && value.length == 12) {
      value = value.substring(2);
    }

    return value;
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone);
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
    });
  }
}
