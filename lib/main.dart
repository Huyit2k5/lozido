import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:lozido_app/presentation/pages/auth/login_page.dart';
import 'package:lozido_app/presentation/pages/home/add_house_page.dart';
import 'package:lozido_app/presentation/pages/main_screen/main_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Tự động đăng nhập ẩn danh để có quyền truy cập Firestore
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    print("Đã đăng nhập ẩn danh với UID: ${userCredential.user?.uid}");
  } catch (e) {
    print("Lỗi đăng nhập: $e");
  }

  runApp(const MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return const RegisterScreen();
=======
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Chờ Firebase kiểm tra trạng thái
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Nếu đã có User (đã đăng nhập) -> Vào phòng chat/trang chủ
        if (snapshot.hasData) {
          return const MainPage();
        }

        // Nếu chưa đăng nhập -> Hiện màn hình Login
        return const LoginScreen();
      },
    );
>>>>>>> c229880500651dba14fcb36a3d830456b515b391
  }
}
