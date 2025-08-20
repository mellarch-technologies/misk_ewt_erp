// lib/services/photo_repository.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'app_config.dart';

abstract class PhotoRepository {
  Future<String> upload(Uint8List bytes, {required String fileName, String mimeType = 'image/jpeg'});
}

class _NoopPhotoRepository implements PhotoRepository {
  @override
  Future<String> upload(Uint8List bytes, {required String fileName, String mimeType = 'image/jpeg'}) async {
    throw StateError('Photo upload backend not configured');
  }
}

class SharedHostingPhotoRepository implements PhotoRepository {
  final PhotoStorageConfig config;
  SharedHostingPhotoRepository(this.config);

  @override
  Future<String> upload(Uint8List bytes, {required String fileName, String mimeType = 'image/jpeg'}) async {
    final url = config.endpointUrl;
    if (url == null || url.isEmpty) {
      throw StateError('Shared hosting endpointUrl is not set');
    }
    final req = http.MultipartRequest('POST', Uri.parse(url));
    req.fields.addAll({
      if (config.apiKey != null) 'apiKey': config.apiKey!,
    });
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = resp.body.trim();
      try {
        final decoded = json.decode(body);
        if (decoded is Map && decoded['url'] is String) return decoded['url'] as String;
      } catch (_) {
        // not JSON
      }
      // Accept plain text URL as fallback
      if (body.startsWith('http')) return body;
    }
    throw StateError('Upload failed (${resp.statusCode}): ${resp.body}');
  }
}

class GoogleDrivePhotoRepository implements PhotoRepository {
  final PhotoStorageConfig config;
  GoogleDrivePhotoRepository(this.config);

  @override
  Future<String> upload(Uint8List bytes, {required String fileName, String mimeType = 'image/jpeg'}) async {
    final url = config.endpointUrl;
    if (url == null || url.isEmpty) {
      throw StateError('Apps Script endpointUrl is not set');
    }
    final req = http.MultipartRequest('POST', Uri.parse(url));
    req.fields.addAll({
      if (config.apiKey != null) 'token': config.apiKey!,
      if (config.driveFolderId != null) 'folderId': config.driveFolderId!,
    });
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = resp.body.trim();
      try {
        final decoded = json.decode(body);
        if (decoded is Map && decoded['url'] is String) return decoded['url'] as String;
        if (decoded is Map && decoded['webViewLink'] is String) return decoded['webViewLink'] as String;
      } catch (_) {}
      if (body.startsWith('http')) return body;
    }
    throw StateError('Upload failed (${resp.statusCode}): ${resp.body}');
  }
}

PhotoRepository getPhotoRepository(PhotoStorageConfig cfg) {
  switch (cfg.backend) {
    case PhotoBackend.sharedHosting:
      return SharedHostingPhotoRepository(cfg);
    case PhotoBackend.googleDrive:
      return GoogleDrivePhotoRepository(cfg);
    case PhotoBackend.none:
      return _NoopPhotoRepository();
  }
}
