import 'dart:io';  // Thêm dòng này để sử dụng lớp File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Thêm để tải ảnh lên Firebase Storage
import '../models/firestore_user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  late FirestoreUserModel _userModel;
  bool _isLoading = true;
  final Logger _logger = Logger();

  FirestoreUserModel get userModel => _userModel;
  bool get isLoading => _isLoading;

  // Phương thức lấy dữ liệu người dùng từ Firestore
  Future<void> fetchUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      if (uid.isEmpty) {
        _logger.e("No user is logged in.");
        _isLoading = false;
        notifyListeners();
        return;
      }

      _logger.i("Fetching user data for uid: $uid");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        _logger.i("User data found: ${userDoc.data()}");
        _userModel = FirestoreUserModel.fromFirestore(userDoc.data()!, userDoc.id);
        _isLoading = false;
        notifyListeners();
      } else {
        _logger.w("User not found");
        _isLoading = false;
        notifyListeners();
      }
    } catch (error) {
      _logger.e("Error fetching user data: $error");
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Phương thức lưu dữ liệu người dùng vào Firestore
  Future<void> saveUserData(String newName) async {
    try {
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      if (uid.isEmpty) {
        _logger.e("No user is logged in.");
        return;
      }

      _logger.i("Saving updated user data for uid: $uid");

      // Cập nhật thông tin người dùng trong Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': newName,
      });

      // Cập nhật dữ liệu trong mô hình sau khi lưu thành công
      _userModel.displayName = newName;

      // Thông báo rằng dữ liệu đã được lưu và UI cần được làm mới
      notifyListeners();

      _logger.i("User data updated successfully.");
    } catch (error) {
      _logger.e("Error saving user data: $error");
      rethrow;
    }
  }

  // Phương thức lưu ảnh đại diện lên Firebase Storage và cập nhật URL vào Firestore
  Future<void> saveAvatar(String filePath) async {
    try {
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      if (uid.isEmpty) {
        _logger.e("No user is logged in.");
        return;
      }

      _logger.i("Saving avatar for uid: $uid");

      // Upload image to Firebase Storage
      File imageFile = File(filePath); // filePath là đường dẫn đến ảnh trên thiết bị
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child("avatars/$uid.jpg");

      await ref.putFile(imageFile); // Upload file
      String avatarUrl = await ref.getDownloadURL(); // Lấy URL của ảnh đã tải lên

      // Cập nhật URL ảnh trong Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'avatarUrl': avatarUrl,
      });

      // Cập nhật avatar URL trong model
      _userModel.avatarUrl = avatarUrl;

      // Thông báo rằng dữ liệu đã được lưu và UI cần được làm mới
      notifyListeners();

      _logger.i("Avatar updated successfully.");
    } catch (error) {
      _logger.e("Error saving avatar: $error");
      rethrow;
    }
  }
}
