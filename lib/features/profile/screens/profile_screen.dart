import 'dart:convert';


import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medilink/services/backup_service.dart';
import 'package:medilink/services/owner_data_service.dart';
import 'package:medilink/services/data_migration_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:medilink/features/auth/screens/login_screen.dart';
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
  bool isLoggingOut = false;
  bool isBackingUp = false;
  bool isMigrating = false;
  bool isRestoring = false;
  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final box = await Hive.openBox<ShopProfile>(
      OwnerDataService.instance.shopProfileBoxName,
    );

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
      final box = await Hive.openBox<ShopProfile>(
        OwnerDataService.instance.shopProfileBoxName,
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



  Future<void> _migrateLegacyData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Migrate existing MediLink data?'),
        content: const Text(
          'This copies existing shared medicines, batches, and shop profile records into the currently signed-in owner’s storage. Continue only if these old records belong to this owner. The original shared records will not be deleted. If this owner already has data in the new storage, migration will stop rather than overwrite it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm migration'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => isMigrating = true);
    try {
      final result = await DataMigrationService()
          .migrateLegacyDataToCurrentOwner(confirmLegacyOwnership: true);
      if (result.alreadyMigrated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Legacy data has already been migrated for this owner.')),
          );
        }
      } else {
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              'Migration verified: ${result.medicinesCopied} medicines, '
                  '${result.batchesCopied} batches, and ${result.profilesCopied} shop profiles copied. '
                  'Original legacy records were preserved.',
            )),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migration stopped: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isMigrating = false);
    }
  }

  Future<void> _createBackup() async {
    if (isBackingUp) return;

    setState(() => isBackingUp = true);
    try {
      final json = await BackupService().createBackupJson();
      if (!mounted) return;

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'medilink_backup_$timestamp.json';

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save MediLink backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );

      if (!mounted) return;
      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup export cancelled.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup file created successfully: $savedPath')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isBackingUp = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (isRestoring) return;

    try {
      final selection = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select MediLink backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (!mounted || selection == null || selection.files.isEmpty) return;

      final selectedFile = selection.files.single;
      final bytes = selectedFile.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException(
          'The selected backup file could not be read.',
        );
      }

      final backupJson = utf8.decode(bytes);
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm backup restore'),
          content: Text(
            'Restore data from "${selectedFile.name}"?\n\n'
                'Records with matching IDs will be updated. Existing unrelated '
                'records will be preserved. The backup must belong to the '
                'currently signed-in owner.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (!mounted || shouldRestore != true) return;

      setState(() => isRestoring = true);
      final result = await BackupService().restoreBackupJson(backupJson);

      await _loadProfile();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore completed: ${result.medicinesRestored} medicines, '
                '${result.batchesRestored} batches, '
                '${result.notesRestored} notes, '
                '${result.customersRestored} customers, '
                '${result.customerMedicinesRestored} frequent-medicine records, '
                'and ${result.paymentsRestored} payments'
                '${result.shopProfileRestored ? ', shop profile restored' : ''}.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isRestoring = false);
    }
  }

  Future<void> _logout() async {
    final bool? shouldLogout =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    setState(() {
      isLoggingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const LoginScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: ${e.message ?? 'Please try again.'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while logging out.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
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
                keyboardType:
                TextInputType.phone,
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

              const SizedBox(height: 18),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Legacy Data Migration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Use this only if your existing shared inventory and shop profile belong to the currently signed-in owner. Migration copies records and preserves the original shared data.'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isMigrating ? null : _migrateLegacyData,
                          icon: isMigrating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.move_to_inbox_outlined),
                          label: Text(isMigrating ? 'Migrating...' : 'Migrate Existing Data'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Backup & Restore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Export all owner data to a JSON file or restore a previously exported backup belonging to the currently signed-in owner.'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (isBackingUp || isRestoring) ? null : _createBackup,
                          icon: isBackingUp ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.backup_outlined),
                          label: Text(isBackingUp ? 'Creating backup...' : 'Export Backup File'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (isBackingUp || isRestoring) ? null : _restoreBackup,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore Backup'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                  isLoggingOut ? null : _logout,
                  icon: isLoggingOut
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  label: Text(
                    isLoggingOut
                        ? 'Logging out...'
                        : 'Logout',
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.red,
                    ),
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