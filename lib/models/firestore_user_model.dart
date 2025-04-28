// models/firestore_user_model.dart
import 'task_model.dart';

class FirestoreUserModel {
  final String uid;
  final String email;
  String displayName;
  String avatarUrl;  // Thêm avatarUrl
  List<TaskModel> tasks;  // Danh sách các công việc

  FirestoreUserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.avatarUrl,  // Thêm avatarUrl
    required this.tasks,
  });

  // Phương thức tạo FirestoreUserModel từ Firestore document
  factory FirestoreUserModel.fromFirestore(Map<String, dynamic> firestoreData, String documentId) {
    var tasksData = firestoreData['tasks'] as List<dynamic>? ?? [];  // Lấy dữ liệu công việc từ Firestore
    List<TaskModel> tasksList = tasksData.map((task) => TaskModel.fromFirestore(task, task['id'])).toList();

    return FirestoreUserModel(
      uid: documentId,
      email: firestoreData['email'] ?? '',
      displayName: firestoreData['displayName'] ?? '',
      avatarUrl: firestoreData['avatarUrl'] ?? '',  // Lấy avatarUrl từ Firestore
      tasks: tasksList,
    );
  }

  // Phương thức chuyển FirestoreUserModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,  // Lưu avatarUrl vào Firestore
      'tasks': tasks.map((task) => task.toMap()).toList(),  // Chuyển đổi danh sách tasks thành Map
    };
  }
}
