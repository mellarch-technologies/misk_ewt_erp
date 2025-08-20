import 'package:flutter_test/flutter_test.dart';
import 'package:misk_ewt_erp/providers/app_lock_provider.dart';

void main() {
  group('AppLockProvider', () {
    test('verifyPin returns true for correct PIN', () {
      final p = AppLockProvider();
      p.debugSetPinForTest('1234');
      expect(p.verifyPin('1234'), isTrue);
      expect(p.verifyPin('0000'), isFalse);
    });

    test('shouldLockNow respects enabled and idle timeout', () async {
      final p = AppLockProvider();
      p.debugSetEnabled(true);
      p.debugSetIdleTimeout(const Duration(minutes: 5));

      // Fresh activity -> should not lock
      p.debugSetLastActivity(DateTime.now());
      expect(p.shouldLockNow(), isFalse);

      // Exceeded idle -> should lock
      p.debugSetLastActivity(DateTime.now().subtract(const Duration(minutes: 6)));
      expect(p.shouldLockNow(), isTrue);
    });

    test('markUnlocked and recordActivity refresh timers', () async {
      final p = AppLockProvider();
      p.debugSetEnabled(true);
      p.debugSetIdleTimeout(const Duration(minutes: 5));

      // Set far in past to trigger lock
      p.debugSetLastActivity(DateTime.now().subtract(const Duration(minutes: 10)));
      expect(p.shouldLockNow(), isTrue);

      // markUnlocked should reset
      p.markUnlocked();
      expect(p.shouldLockNow(), isFalse);

      // Advance to near the timeout and recordActivity should keep it unlocked
      p.debugSetLastActivity(DateTime.now().subtract(const Duration(minutes: 4, seconds: 50)));
      expect(p.shouldLockNow(), isFalse);
      p.recordActivity();
      expect(p.shouldLockNow(), isFalse);
    });
  });
}

