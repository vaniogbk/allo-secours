import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../core/constants/app_config.dart';

class StorageService {
  final _picker = ImagePicker();

  // ── PICK IMAGE DEPUIS GALERIE ──
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      return null;
    }
  }

  // ── PICK MULTIPLE IMAGES ──
  Future<List<XFile>> pickMultipleImages() async {
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1080,
        imageQuality: 85,
      );
      return picked;
    } catch (e) {
      return [];
    }
  }

  // ── UPLOAD VERS CLOUDINARY ──
  Future<String> uploadFile(XFile file, String folder) async {
    try {
      final filename = path.basename(file.name);
      final ext = path.extension(filename).replaceAll('.', '').toLowerCase();
      final mimeType = _getMimeType(ext);

      final uri = Uri.parse(AppConfig.cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri);

      // Paramètres Cloudinary
      request.fields['upload_preset'] = AppConfig.cloudinaryUploadPreset;
      request.fields['folder'] = 'logitrack/$folder';
      request.fields['api_key'] = AppConfig.cloudinaryApiKey;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
            contentType: MediaType('image', mimeType),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType('image', mimeType),
          ),
        );
      }

      final streamResponse = await request.send();
      final responseBody = await streamResponse.stream.bytesToString();
      final jsonData = json.decode(responseBody) as Map<String, dynamic>;

      if (streamResponse.statusCode == 200) {
        final url = jsonData['secure_url'] as String;
        return url;
      } else {
        final errorMsg = jsonData['error']?['message'] ?? 'Erreur inconnue';
        throw Exception('Cloudinary: $errorMsg');
      }
    } catch (e) {
      throw Exception('Erreur upload image: $e');
    }
  }

  // ── UPLOAD MULTIPLE ──
  Future<List<String>> uploadMultiple(
    List<XFile> files,
    String folder,
  ) async {
    final urls = <String>[];
    for (final file in files) {
      try {
        final url = await uploadFile(file, folder);
        if (url.isNotEmpty) urls.add(url);
      } catch (e) {
        // Continue même si une image échoue
        continue;
      }
    }
    return urls;
  }

  // ── SUPPRIMER (non supporté sans serveur) ──
  Future<void> deleteFile(String url) async {
    // La suppression nécessite une signature côté serveur
    // Laissé pour une future implémentation
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg';
    }
  }
}
