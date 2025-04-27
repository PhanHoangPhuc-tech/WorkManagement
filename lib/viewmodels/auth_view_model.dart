import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:logger/logger.dart';  

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _user;
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  // Khởi tạo logger
  var logger = Logger();

  // Đăng nhập với Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;  // Người dùng hủy đăng nhập

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      _user = UserModel.fromFirebaseUser(userCredential.user!);

      notifyListeners();  // Cập nhật trạng thái người dùng
    } catch (e) {
      logger.e("Google sign-in error: $e");  // Thay vì print, sử dụng logger
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }
}
