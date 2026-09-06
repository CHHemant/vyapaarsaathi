// frontend/lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/kirana_colors.dart';
import '../widgets/rupee_button.dart';
import '../widgets/kirana_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    _storeNameController = TextEditingController(text: user?.storeName ?? '');
    _ownerNameController = TextEditingController(text: user?.ownerName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: KiranaColors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.onSurface, width: 2),
                ),
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.onSurface,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),

              // Store Name
              KiranaCard(
                child: TextFormField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Store Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter store name';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Owner Name
              KiranaCard(
                child: TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Owner Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter owner name';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Phone Number
              KiranaCard(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    counterText: "",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter phone number';
                    }
                    if (value.length != 10) {
                      return 'Enter valid 10-digit number';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Email
              KiranaCard(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              RupeeButton(
                label: 'Save Changes',
                icon: Icons.save,
                showRupeePrefix: false,
                fullWidth: true,
                onPressed: _saveProfile,
              ),

              const SizedBox(height: 16),

              // Cancel Button
              RupeeButton(
                label: 'Cancel',
                icon: Icons.close,
                showRupeePrefix: false,
                fullWidth: true,
                color: KiranaColors.paper,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();

      if (currentUser != null) {
        final updated = currentUser.copyWith(
          storeName: _storeNameController.text,
          ownerName: _ownerNameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          city: _cityController.text.isEmpty ? null : _cityController.text,
        );

        await authService.updateProfile(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      }
    }
  }
}