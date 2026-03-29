import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Domain giả định dùng để map số điện thoại sang email
  static const String _domain = '@lozido.com';

  Future<User?> registerWithPhoneNumber({
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // 1. Tạo email giả lập từ số điện thoại
      final String email = '$phoneNumber$_domain';

      // 2. Tạo tài khoản trong Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Cập nhật tên hiển thị cho user auth
        await user.updateDisplayName(name);

        // 3. Thêm document mới vào collection 'users' trong Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Số điện thoại này đã được đăng ký. Vui lòng đăng nhập.');
      }
      throw Exception('Lỗi đăng ký Firebase: ${e.message}');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định: $e');
    }
  }

  Future<User?> loginWithPhoneNumber({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Tái lập email mặc định từ số điện thoại đã sử dụng để đăng ký
      final String email = '$phoneNumber$_domain';

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Bắt các mã lỗi tương ứng với quá trình Login
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Sai số điện thoại hoặc mật khẩu. Vui lòng thử lại.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Tài khoản này đã bị hệ thống khoá.');
      }
      throw Exception('Lỗi đăng nhập Firebase: ${e.message}');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định: $e');
    }
  }
}
