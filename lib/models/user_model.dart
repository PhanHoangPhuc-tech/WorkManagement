import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  // Tạo đối tượng UserModel từ Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName ?? 'Unknown',
      email: user.email ?? 'Unknown',
      photoUrl: user.photoURL ?? '',
    );
  }
}
