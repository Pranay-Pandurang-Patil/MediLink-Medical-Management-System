import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:medilink/models/shop_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController shopNameController =
  TextEditingController();

  final TextEditingController ownerNameController =
  TextEditingController();

  final TextEditingController phoneController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController addressController =
  TextEditingController();

  final TextEditingController openingTimeController =
  TextEditingController();

  final TextEditingController closingTimeController =
  TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final box =
    await Hive.openBox<ShopProfile>('shop_profile');

    if (box.isNotEmpty) {
      final profile = box.getAt(0);

      if (profile == null || !mounted) {
        return;
      }

      setState(() {
        shopNameController.text =
            profile.shopName;

        ownerNameController.text =
            profile.ownerName;

        phoneController.text =
            profile.phone;

        emailController.text =
            profile.email;

        addressController.text =
            profile.address;

        openingTimeController.text =
            profile.openingTime;

        closingTimeController.text =
            profile.closingTime;
      });
    }
  }

  @override
  void dispose() {
    shopNameController.dispose();
    ownerNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    openingTimeController.dispose();
    closingTimeController.dispose();

    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final box =
      await Hive.openBox<ShopProfile>(
        'shop_profile',
      );

      final profile = ShopProfile(
        shopName:
        shopNameController.text.trim(),
        ownerName:
        ownerNameController.text.trim(),
        phone:
        phoneController.text.trim(),
        email:
        emailController.text.trim(),
        address:
        addressController.text.trim(),
        openingTime:
        openingTimeController.text.trim(),
        closingTime:
        closingTimeController.text.trim(),
      );

      await box.clear();
      await box.add(profile);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Shop profile saved successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save profile: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Shop Information',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Manage your medical shop information',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 28),

              _ProfileField(
                controller: shopNameController,
                label: 'Shop Name',
                hint: 'Enter shop name',
                icon: Icons.store_outlined,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter shop name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              _ProfileField(
                controller: ownerNameController,
                label: 'Owner Name',
                hint: 'Enter owner name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter owner name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              _ProfileField(
                controller: phoneController,
                label: 'Phone',
                hint: 'Enter phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 18),

              _ProfileField(
                controller: emailController,
                label: 'Email',
                hint: 'Enter email address',
                icon: Icons.email_outlined,
                keyboardType:
                TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              _ProfileField(
                controller: addressController,
                label: 'Address',
                hint: 'Enter shop address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 18),

              _ProfileField(
                controller: openingTimeController,
                label: 'Opening Time',
                hint: 'e.g. 09:00 AM',
                icon: Icons.access_time_outlined,
              ),

              const SizedBox(height: 18),

              _ProfileField(
                controller: closingTimeController,
                label: 'Closing Time',
                hint: 'e.g. 09:00 PM',
                icon: Icons.access_time_outlined,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                  isSaving ? null : _saveProfile,
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: Text(
                    isSaving
                        ? 'Saving...'
                        : 'Save Profile',
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
        ),
      ),
    );
  }
}