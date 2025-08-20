// lib/services/photo_service.dart
class PhotoService {
  /// Returns a placeholder avatar URL using ui-avatars.com based on the provided [name].
  /// No storage is used; this is suitable as a temporary photo URL.
  static String avatarUrlForName(String name, {int size = 256, String bg = '0D8ABC', String color = 'fff'}) {
    final encoded = Uri.encodeComponent(name.trim().isEmpty ? 'User' : name.trim());
    return 'https://ui-avatars.com/api/?name=$encoded&background=$bg&color=$color&size=$size&bold=true&rounded=true';
  }
}

