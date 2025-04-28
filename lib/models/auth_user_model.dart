// models/auth_user_model.dart
import 'package:firebase_auth/firebase_auth.dart';  // Import firebase_auth

class UserModel {
  final String uid;
  final String displayName;
  final String email;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
  });

  // Tạo đối tượng UserModel từ Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName ?? '',  // Nếu không có displayName, để trống
      email: user.email ?? 'Unknown',  // Nếu không có email, gán mặc định 'Unknown'
    );
  }

  // Chuyển UserModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
    };
  }
}
