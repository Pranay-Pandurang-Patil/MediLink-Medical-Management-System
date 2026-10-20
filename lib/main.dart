import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'models/customer_medicine.dart';
import 'models/customer_payment.dart';
import 'models/daily_note.dart';
import 'models/medicine.dart';
import 'models/medicine_batch.dart';
import 'models/regular_customer.dart';
import 'models/shop_profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register all adapters before opening Hive boxes.
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MedicineAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MedicineBatchAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ShopProfileAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyNoteAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(RegularCustomerAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(CustomerMedicineAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(CustomerPaymentAdapter());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediLink',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
