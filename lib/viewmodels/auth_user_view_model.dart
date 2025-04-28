import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore
import '../models/auth_user_model.dart';  // Đảm bảo import đúng từ auth_user_model.dart
import 'package:logger/logger.dart';
import 'package:workmanagement/screens/tabs/home_page.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;  // Firestore instance

  UserModel? _user;  // Sử dụng UserModel từ auth_user_model.dart
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  // Khởi tạo logger
  var logger = Logger();

  // Đăng nhập với Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;  // Người dùng hủy đăng nhập
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      _user = UserModel.fromFirebaseUser(userCredential.user!);  // Đảm bảo gọi từ đúng UserModel

      // Lưu thông tin người dùng vào Firestore nếu là lần đầu đăng nhập
      await _saveUserToFirestore(_user!);

      notifyListeners();  

      final userId = userCredential.user?.uid ?? "";
      
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userId: userId), 
          ),
        );
      }
    } catch (e) {
      logger.e("Google sign-in error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thất bại. Vui lòng thử lại.')),
        );
      }
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

  // Lưu thông tin người dùng vào Firestore
  Future<void> _saveUserToFirestore(UserModel userModel) async {
    try {
      DocumentReference userDocRef = _firestore.collection('users').doc(userModel.uid);
      DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // Nếu tài liệu người dùng chưa tồn tại, tạo mới
        await userDocRef.set(userModel.toMap());
        logger.i('User saved to Firestore');
      } else {
        logger.i('User already exists in Firestore');
      }
    } catch (e) {
      logger.e('Error saving user to Firestore: $e');
    }
  }
}
