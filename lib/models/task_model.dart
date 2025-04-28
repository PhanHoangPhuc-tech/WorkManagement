// models/task_model.dart

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String? dueDate;
  final String status;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.status,
  });

  // Phương thức tạo TaskModel từ Firestore document
  factory TaskModel.fromFirestore(Map<String, dynamic> firestoreData, String documentId) {
    return TaskModel(
      id: documentId,
      title: firestoreData['title'] ?? '',
      description: firestoreData['description'],
      dueDate: firestoreData['dueDate'],
      status: firestoreData['status'] ?? 'pending',  // Mặc định là 'pending'
    );
  }

  // Phương thức chuyển TaskModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'status': status,
    };
  }
}
