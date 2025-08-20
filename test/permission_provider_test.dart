import 'package:flutter_test/flutter_test.dart';
import 'package:misk_ewt_erp/providers/permission_provider.dart';
import 'package:misk_ewt_erp/models/role_model.dart';

void main() {
  group('PermissionProvider', () {
    test('returns true for super admin for any permission', () {
      final provider = PermissionProvider();
      provider.debugSetRole(null, isSuperAdmin: true);

      expect(provider.isSuperAdmin, isTrue);
      expect(provider.roleName, 'Super Admin');
      expect(provider.can('any.permission.key'), isTrue);
    });

    test('returns permission based on role map', () {
      final provider = PermissionProvider();
      final role = Role(
        id: 'r1',
        name: 'Manager',
        permissions: {
          'can_manage_users': true,
          'can_view_reports': false,
        },
      );

      provider.debugSetRole(role, isSuperAdmin: false);

      expect(provider.isSuperAdmin, isFalse);
      expect(provider.roleName, 'Manager');
      expect(provider.can('can_manage_users'), isTrue);
      expect(provider.can('can_view_reports'), isFalse);
      expect(provider.can('unknown_permission'), isFalse);
    });

    test('clears permissions', () {
      final provider = PermissionProvider();
      final role = Role(id: 'r2', name: 'Viewer', permissions: {});
      provider.debugSetRole(role);
      expect(provider.userRole, isNotNull);

      provider.clearPermissions();
      expect(provider.userRole, isNull);
      expect(provider.isSuperAdmin, isFalse);
    });
  });
}

