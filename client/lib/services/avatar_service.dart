import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AvatarService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<File?> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<String?> saveAvatar(File imageFile, int userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${directory.path}/avatars');
      
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      
      final fileName = 'user_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${avatarDir.path}/$fileName';
      
      await imageFile.copy(savedPath);
      return savedPath;
    } catch (e) {
      print('Ошибка сохранения аватарки: $e');
      return null;
    }
  }

  Future<void> deleteAvatar(String avatarPath) async {
    try {
      final file = File(avatarPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Ошибка удаления аватарки: $e');
    }
  }
}