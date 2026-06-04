import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> login(String phoneNumber, String password, bool isTenantMode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isTenantMode) {
        final tenantSnap = await _firestore
            .collection('tenants')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();

        if (tenantSnap.docs.isEmpty) {
          throw Exception('Tài khoản người thuê không tồn tại cho số điện thoại này.');
        }

        final tenantData = tenantSnap.docs.first.data();
        final storedPassword = tenantData['password']?.toString();

        if (storedPassword != password) {
          throw Exception('Mật khẩu người thuê không chính xác.');
        }

        final tenantEmail = tenantData['email']?.toString() ?? '$phoneNumber@irental.com';
        final tenantAuthPassword = storedPassword ?? password;

        await _authRepository.loginWithPhoneNumber(
          phoneNumber: tenantEmail.replaceAll('@irental.com', ''),
          password: tenantAuthPassword,
        );
      } else {
        await _authRepository.loginWithPhoneNumber(
          phoneNumber: phoneNumber,
          password: password,
        );
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ConfirmationResult> verifyPhoneForRegistration({required String phoneNumber}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _authRepository.verifyPhoneForRegistration(phoneNumber: phoneNumber);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeRegistration({
    required ConfirmationResult confirmationResult,
    required String smsCode,
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.completeRegistration(
        confirmationResult: confirmationResult,
        smsCode: smsCode,
        name: name,
        phoneNumber: phoneNumber,
        password: password,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
