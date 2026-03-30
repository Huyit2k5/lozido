import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Domain giả định dùng để map số điện thoại sang email
  static const String _domain = '@lozido.com';

  Future<ConfirmationResult> verifyPhoneForRegistration({
    required String phoneNumber,
  }) async {
    try {
      // Format 098 -> +8498
      String phone = phoneNumber;
      if (phone.startsWith('0')) {
        phone = '+84${phone.substring(1)}';
      }
      return await _auth.signInWithPhoneNumber(phone);
    } catch (e) {
      throw Exception('Lỗi xác thực số điện thoại: $e');
    }
  }

  Future<User?> completeRegistration({
    required ConfirmationResult confirmationResult,
    required String smsCode,
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // 1. Xác thực OTP để cấu thành Account gốc (Phone Auth)
      UserCredential userCredential = await confirmationResult.confirm(smsCode);
      User? user = userCredential.user;

      if (user != null) {
        // 2. Tạo liên kết Đăng nhập phụ (Fake Email + Password)
        final String email = '$phoneNumber$_domain';
        AuthCredential emailCredential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        // Khóa chặt 2 chuẩn thành 1 Identity
        await user.linkWithCredential(emailCredential);

        // 3. Cập nhật MetaData
        await user.updateDisplayName(name);

        // 4. Lưu Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
        throw Exception('Số điện thoại hoặc thông tin này đã được đăng ký. Vui lòng đăng nhập.');
      } else if (e.code == 'invalid-verification-code') {
        throw Exception('Mã OTP không hợp lệ.');
      } else if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.');
      }
      throw Exception('Lỗi đăng ký Firebase: ${e.message}');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi hệ thống: $e');
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
