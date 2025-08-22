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
  static PhotoStorageConfig photoStorage = _loadPhotoStorageFromEnv();

  static PhotoStorageConfig _loadPhotoStorageFromEnv() {
    const backendStr = String.fromEnvironment('PHOTO_BACKEND', defaultValue: 'none');
    const endpoint = String.fromEnvironment('SHARED_ENDPOINT_URL');
    const apiKey = String.fromEnvironment('SHARED_API_KEY');
    const folderId = String.fromEnvironment('DRIVE_FOLDER_ID');

    PhotoBackend backend;
    switch (backendStr.toLowerCase()) {
      case 'sharedhosting':
      case 'shared_hosting':
      case 'shared':
        backend = PhotoBackend.sharedHosting;
        break;
      case 'googledrive':
      case 'drive':
        backend = PhotoBackend.googleDrive;
        break;
      default:
        backend = PhotoBackend.none;
    }

    return PhotoStorageConfig(
      backend: backend,
      endpointUrl: endpoint.isEmpty ? null : endpoint,
      apiKey: apiKey.isEmpty ? null : apiKey,
      driveFolderId: folderId.isEmpty ? null : folderId,
    );
  }
}
