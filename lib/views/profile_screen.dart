import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Thêm package cho việc chọn ảnh từ thư viện
import '../viewmodels/profile_view_model.dart';

class ProfileSettingScreen extends StatefulWidget {
  const ProfileSettingScreen({super.key});

  @override
  ProfileSettingScreenState createState() => ProfileSettingScreenState();
}

class ProfileSettingScreenState extends State<ProfileSettingScreen> {
  late Future<void> _userData;
  bool isEditing = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userData = Provider.of<ProfileViewModel>(context, listen: false).fetchUserData();
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Save the avatar and update Firestore
      String filePath = pickedFile.path;

      // Kiểm tra xem widget còn mounted không trước khi gọi setState
      if (mounted) {
        await Provider.of<ProfileViewModel>(context, listen: false).saveAvatar(filePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt Hồ sơ',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder(
        future: _userData,
        builder: (context, snapshot) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // Căn phần tử lên phía trên
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hiển thị avatar (hình ảnh đại diện)
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(viewModel.userModel.avatarUrl), // Dùng URL ảnh đại diện
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage, // Chọn ảnh khi nhấn vào nút tròn
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(
                                Icons.camera_alt, // Biểu tượng máy ảnh
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    isEditing
                        ? Column(
                            children: [
                              TextField(
                                controller: _nameController..text = viewModel.userModel.displayName,
                                decoration: const InputDecoration(labelText: 'Tên'),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Text(
                                viewModel.userModel.displayName,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                viewModel.userModel.email,
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isEditing) {
                          String newName = _nameController.text;
                          viewModel.saveUserData(newName);
                          setState(() {
                            isEditing = false;
                          });
                        } else {
                          setState(() {
                            isEditing = true;
                          });
                        }
                      },
                      icon: Icon(isEditing ? Icons.save : Icons.edit),
                      label: Text(isEditing ? 'Lưu' : 'Chỉnh sửa'),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Không có dữ liệu'));
        },
      ),
    );
  }
}
