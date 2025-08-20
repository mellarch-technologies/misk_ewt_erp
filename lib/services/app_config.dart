// lib/services/app_config.dart

/// Photo storage backends supported without Firebase Storage.
enum PhotoBackend { none, sharedHosting, googleDrive }

class PhotoStorageConfig {
  final PhotoBackend backend;
  final String? endpointUrl; // Shared hosting PHP endpoint or Apps Script URL
  final String? apiKey; // Optional API key or HMAC token
  final String? driveFolderId; // For Google Drive adapter

  const PhotoStorageConfig({
    required this.backend,
    this.endpointUrl,
    this.apiKey,
    this.driveFolderId,
  });
}

/// Central app config. In production, consider wiring via flavors or dart-define.
class AppConfig {
  static PhotoStorageConfig photoStorage = const PhotoStorageConfig(
    backend: PhotoBackend.none,
  );
}

