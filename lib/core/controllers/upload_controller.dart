import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class UploadController {
  static final UploadController instance = UploadController._internal();
  UploadController._internal();

  final ImagePicker _picker = ImagePicker();

  /// Picks an image and returns the original XFile
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth = 1024,
    double? maxHeight = 1024,
    int? imageQuality,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    } catch (e) {
      debugPrint('FCM UploadController: Error picking image: $e');
      return null;
    }
  }

  /// Uploads a file to the profile-pic endpoint
  Future<String?> uploadProfilePicture(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return await RepairRepository.instance.uploadProfilePic(bytes, file.name);
    } catch (e) {
      debugPrint('FCM UploadController: Error uploading profile pic: $e');
      return null;
    }
  }

  /// Uploads a file to the repair/evidence endpoint
  Future<String?> uploadRepairImage(XFile file) async {
    try {
      return await RepairRepository.instance.uploadImage(file);
    } catch (e) {
      debugPrint('FCM UploadController: Error uploading repair image: $e');
      return null;
    }
  }
}
