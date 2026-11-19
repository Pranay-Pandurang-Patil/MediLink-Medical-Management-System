import 'package:flutter/material.dart';

import 'package:medilink/models/medicine.dart';
import 'package:medilink/services/medicine_service.dart';
import 'package:medilink/shared/widgets/custom_button.dart';
import 'package:medilink/shared/widgets/custom_text_field.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;

  const AddMedicineScreen({
    super.key,
    this.medicine,
  });

  @override
  State<AddMedicineScreen> createState() =>
      _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  final MedicineService medicineService = MedicineService();

  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController genericNameController =
  TextEditingController();

  final TextEditingController manufacturerController =
  TextEditingController();

  final TextEditingController categoryController =
  TextEditingController();

  final TextEditingController unitController =
  TextEditingController();

  final TextEditingController priceController =
  TextEditingController();

  final TextEditingController minimumStockController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  bool isSaving = false;

  bool get isEditing => widget.medicine != null;

  @override
  void initState() {
    super.initState();

    final medicine = widget.medicine;

    if (medicine != null) {
      nameController.text = medicine.name;
      genericNameController.text = medicine.genericName;
      manufacturerController.text = medicine.manufacturer;
      categoryController.text = medicine.category;
      unitController.text = medicine.unit;

      priceController.text =
          medicine.sellingPrice.toStringAsFixed(2);

      minimumStockController.text =
          medicine.minimumStock.toString();

      descriptionController.text = medicine.description;
    } else {
      minimumStockController.text = '0';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    genericNameController.dispose();
    manufacturerController.dispose();
    categoryController.dispose();
    unitController.dispose();
    priceController.dispose();
    minimumStockController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter medicine name';
    }

    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter selling price';
    }

    final price = double.tryParse(value.trim());

    if (price == null || !price.isFinite || price < 0) {
      return 'Please enter a valid price';
    }

    return null;
  }

  String? _validateMinimumStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final minimumStock = int.tryParse(value.trim());

    if (minimumStock == null || minimumStock < 0) {
      return 'Please enter a valid quantity';
    }

    return null;
  }

  Future<void> _saveMedicine() async {
    if (isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await medicineService.openBox();

      final medicine = Medicine(
        id: widget.medicine?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),

        name: nameController.text.trim(),

        genericName: genericNameController.text.trim(),

        manufacturer: manufacturerController.text.trim(),

        category: categoryController.text.trim(),

        unit: unitController.text.trim(),

        sellingPrice: double.parse(
          priceController.text.trim(),
        ),

        description: descriptionController.text.trim(),

        minimumStock: minimumStockController.text.trim().isEmpty
            ? 0
            : int.parse(minimumStockController.text.trim()),
      );

      await medicineService.box.put(
        medicine.id,
        medicine,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Medicine updated successfully'
                : 'Medicine added successfully',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save medicine: $e'),
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
        title: Text(
          isEditing ? 'Edit Medicine' : 'Add Medicine',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Update Medicine' : 'Add New Medicine',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isEditing
                    ? 'Update medicine information'
                    : 'Enter medicine information',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 28),

              CustomTextField(
                controller: nameController,
                labelText: 'Medicine Name',
                hintText: 'Enter medicine name',
                prefixIcon: Icons.medication_outlined,
                validator: _validateName,
              ),

              const SizedBox(height: 18),

              CustomTextField(
                controller: genericNameController,
                labelText: 'Generic Name',
                hintText: 'Enter generic name',
                prefixIcon: Icons.science_outlined,
              ),

              const SizedBox(height: 18),

              CustomTextField(
                controller: manufacturerController,
                labelText: 'Manufacturer',
                hintText: 'Enter manufacturer',
                prefixIcon: Icons.business_outlined,
              ),

              const SizedBox(height: 18),

              CustomTextField(
                controller: categoryController,
                labelText: 'Category',
                hintText: 'e.g. Tablet, Syrup, Capsule',
                prefixIcon: Icons.category_outlined,
              ),

              const SizedBox(height: 18),

              CustomTextField(
                controller: unitController,
                labelText: 'Unit / Pack',
                hintText: 'e.g. 10 tablets',
                prefixIcon: Icons.inventory_2_outlined,
              ),

              const SizedBox(height: 18),

              CustomTextField(
                controller: priceController,
                labelText: 'Selling Price',
                hintText: 'Enter selling price',
                prefixIcon: Icons.currency_rupee,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validatePrice,
              ),

              const SizedBox(height: 18),

              CustomTextField(
                controller: minimumStockController,
                labelText: 'Minimum Stock',
                hintText: 'Alert when stock reaches this level',
                prefixIcon: Icons.warning_amber_outlined,
                keyboardType: TextInputType.number,
                validator: _validateMinimumStock,
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter medicine description',
                  prefixIcon: const Icon(
                    Icons.description_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              CustomButton(
                text: isSaving
                    ? 'Saving...'
                    : isEditing
                    ? 'Update Medicine'
                    : 'Save Medicine',
                icon: isEditing
                    ? Icons.save_outlined
                    : Icons.add,
                onPressed: isSaving ? () {} : _saveMedicine,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}