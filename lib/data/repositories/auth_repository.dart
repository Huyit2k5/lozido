import 'package:firebase_auth/firebase_auth.dart';
import '../datasources/firebase_auth_service.dart';

class AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepository({FirebaseAuthService? authService})
      : _authService = authService ?? FirebaseAuthService();

  Future<ConfirmationResult> verifyPhoneForRegistration({required String phoneNumber}) {
    return _authService.verifyPhoneForRegistration(phoneNumber: phoneNumber);
  }

  Future<User?> completeRegistration({
    required ConfirmationResult confirmationResult,
    required String smsCode,
    required String name,
    required String phoneNumber,
    required String password,
  }) {
    return _authService.completeRegistration(
      confirmationResult: confirmationResult,
      smsCode: smsCode,
      name: name,
      phoneNumber: phoneNumber,
      password: password,
    );
  }

  Future<User?> loginWithPhoneNumber({
    required String phoneNumber,
    required String password,
  }) {
    return _authService.loginWithPhoneNumber(
      phoneNumber: phoneNumber,
      password: password,
    );
  }
}
