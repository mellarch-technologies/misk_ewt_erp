// lib/providers/app_lock_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

class AppLockProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  AppLockProvider({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  bool _enabled = false;
  bool _biometricEnabled = false;
  Duration _idleTimeout = const Duration(minutes: 15);
  String? _pinHash; // sha256 hex
  DateTime? _lastActivity;
  DateTime? _lastUnlock;
  Timer? _idleTicker;

  bool get enabled => _enabled;
  bool get biometricEnabled => _biometricEnabled;
  Duration get idleTimeout => _idleTimeout;
  DateTime? get lastActivity => _lastActivity;
  DateTime? get lastUnlock => _lastUnlock;

  Future<void> load() async {
    _enabled = (await _storage.read(key: 'applock_enabled')) == 'true';
    _biometricEnabled = (await _storage.read(key: 'applock_bio')) == 'true';
    final idleSecs = int.tryParse(await _storage.read(key: 'applock_idle_secs') ?? '') ?? 900;
    _idleTimeout = Duration(seconds: idleSecs);
    _pinHash = await _storage.read(key: 'applock_pin');
    _lastActivity = DateTime.now();
    _lastUnlock = DateTime.now();
    _startIdleTicker();
    notifyListeners();
  }

  void _startIdleTicker() {
    _idleTicker?.cancel();
    _idleTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_enabled) notifyListeners();
    });
  }

  @override
  void dispose() {
    _idleTicker?.cancel();
    super.dispose();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _storage.write(key: 'applock_enabled', value: value.toString());
    if (value) {
      _lastActivity = DateTime.now();
      _lastUnlock = DateTime.now();
      _startIdleTicker();
    }
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    await _storage.write(key: 'applock_bio', value: value.toString());
    notifyListeners();
  }

  Future<void> setIdleTimeout(Duration value) async {
    _idleTimeout = value;
    await _storage.write(key: 'applock_idle_secs', value: value.inSeconds.toString());
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    _pinHash = _hash(pin);
    await _storage.write(key: 'applock_pin', value: _pinHash);
    notifyListeners();
  }

  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;

  bool verifyPin(String pin) => _pinHash != null && _pinHash == _hash(pin);

  void recordActivity() {
    // Do not record activity while locked; require explicit unlock
    if (_enabled && shouldLockNow()) {
      return;
    }
    _lastActivity = DateTime.now();
    notifyListeners();
  }

  void markUnlocked() {
    _lastUnlock = DateTime.now();
    _lastActivity = DateTime.now();
    notifyListeners();
  }

  bool shouldLockNow() {
    if (!_enabled) return false;
    final now = DateTime.now();
    if (_lastUnlock == null || _lastActivity == null) return true;
    final idle = now.difference(_lastActivity!);
    return idle >= _idleTimeout;
  }

  void forceLockNow() {
    if (!_enabled) return;
    // Set lastActivity far in the past so shouldLockNow() returns true
    _lastActivity = DateTime.now().subtract(_idleTimeout);
    notifyListeners();
  }

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();

  @visibleForTesting
  void debugSetEnabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetIdleTimeout(Duration value) {
    _idleTimeout = value;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetPinForTest(String pin) {
    _pinHash = _hash(pin);
    notifyListeners();
  }

  @visibleForTesting
  void debugSetLastActivity(DateTime dt) {
    _lastActivity = dt;
    notifyListeners();
  }
}
