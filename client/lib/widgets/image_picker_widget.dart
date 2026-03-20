import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:synapse/services/image_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final List<String> imagePaths;
  final Function(List<String>) onImagesChanged;
  final int noteId;

  const ImagePickerWidget({
    super.key,
    required this.imagePaths,
    required this.onImagesChanged,
    required this.noteId,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImageService _imageService = ImageService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final savedPath = await _imageService.saveImage(file, widget.noteId);
      if (savedPath != null) {
        final newPaths = List<String>.from(widget.imagePaths)..add(savedPath);
        widget.onImagesChanged(newPaths);
      }
    }
  }

  Future<void> _removeImage(String path) async {
    await _imageService.deleteImage(path);
    final newPaths = List<String>.from(widget.imagePaths)..remove(path);
    widget.onImagesChanged(newPaths);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Изображения', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.imagePaths.map((path) => Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(File(path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => _removeImage(path),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                ),
                child: Icon(Icons.add_photo_alternate, color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}