import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:lozido_app/presentation/pages/auth/auth_wrapper.dart';
import 'package:lozido_app/viewmodels/task_viewmodel.dart';
import 'package:lozido_app/viewmodels/auth_viewmodel.dart';
import 'package:lozido_app/viewmodels/chat_viewmodel.dart';
import 'package:lozido_app/viewmodels/house_viewmodel.dart';
import 'package:lozido_app/viewmodels/invoice_viewmodel.dart';
import 'package:lozido_app/viewmodels/finance_viewmodel.dart';
import 'package:lozido_app/viewmodels/contract_viewmodel.dart';
import 'package:lozido_app/viewmodels/tenant_viewmodel.dart';
import 'package:lozido_app/viewmodels/service_viewmodel.dart';
import 'package:lozido_app/viewmodels/deposit_viewmodel.dart';
import 'package:lozido_app/viewmodels/asset_viewmodel.dart';
import 'package:lozido_app/viewmodels/vehicle_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await initializeDateFormatting('vi_VN', null);
  
  // Tự động đăng nhập ẩn danh nếu chưa đăng nhập bất kỳ tài khoản nào
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint("Đã đăng nhập ẩn danh với UID: ${userCredential.user?.uid}");
    }
  } catch (e) {
    debugPrint("Lỗi đăng nhập: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => HouseViewModel()),
        ChangeNotifierProvider(create: (_) => InvoiceViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
        ChangeNotifierProvider(create: (_) => ContractViewModel()),
        ChangeNotifierProvider(create: (_) => TenantViewModel()),
        ChangeNotifierProvider(create: (_) => ServiceViewModel()),
        ChangeNotifierProvider(create: (_) => DepositViewModel()),
        ChangeNotifierProvider(create: (_) => AssetViewModel()),
        ChangeNotifierProvider(create: (_) => VehicleViewModel()),
      ],
      child: const MaterialApp(
        home: MyApp(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthWrapper();
  }
}
