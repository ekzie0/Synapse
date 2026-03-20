import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Выбрать изображение из галереи
  Future<File?> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Сделать фото на камеру
  Future<File?> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Сохранить изображение в папку приложения
  Future<String?> saveImage(File imageFile, int noteId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/note_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final fileName = 'note_${noteId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${imagesDir.path}/$fileName';
      
      await imageFile.copy(savedPath);
      return savedPath;
    } catch (e) {
      print('Ошибка сохранения изображения: $e');
      return null;
    }
  }

  // Удалить изображение
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Ошибка удаления изображения: $e');
    }
  }

  // Получить все изображения заметки
  Future<List<File>> getImagesForNote(List<String> imagePaths) async {
    List<File> images = [];
    for (String path in imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        images.add(file);
      }
    }
    return images;
  }
}