import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecureStorageService {
  static const _pinHashKey = 'pinHash';
  static const _appLockEnabledKey = 'appLockEnabled';

  final FlutterSecureStorage _storage;

  SecureStorageService() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinHashKey, value: _hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  Future<bool> hasPin() async {
    return await _storage.containsKey(key: _pinHashKey) &&
        (await _storage.read(key: _pinHashKey)) != null;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(key: _appLockEnabledKey, value: enabled.toString());
  }

  Future<bool> getAppLockEnabled() async {
    final val = await _storage.read(key: _appLockEnabledKey);
    return val == 'true';
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
