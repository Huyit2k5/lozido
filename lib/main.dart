import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:lozido_app/presentation/pages/auth/auth_wrapper.dart';

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

  runApp(const MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthWrapper();
  }
}

