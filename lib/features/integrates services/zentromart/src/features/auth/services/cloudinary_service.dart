import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // Your real Cloudinary credentials are now wired up!
  final cloudinary = CloudinaryPublic(
      'dpzyfkakh', // Your Cloud Name
      'zentromart_preset', // Your Unsigned Upload Preset
      cache: false);

  Future<String?> uploadImage(File imageFile) async {
    try {
      // FIXED: Strip 'file://' prefix from the string path so the native file reader
      // can locate the physical file asset on the Android/iOS disk layout perfectly.
      final String cleanPath = imageFile.path.replaceAll('file://', '');
      final File fileToUpload = File(cleanPath);

      if (!await fileToUpload.exists()) {
        print(
            "Cloudinary Service Warning: The target file does not exist at path: $cleanPath");
        return null;
      }

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          fileToUpload.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print(
          "Cloudinary Asset Upload Successful! Target Link: ${response.secureUrl}");
      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      return null;
    }
  }
}
