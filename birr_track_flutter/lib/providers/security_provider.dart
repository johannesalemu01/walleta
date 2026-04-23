import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../data/storage/secure_storage_service.dart';

class SecurityProvider extends ChangeNotifier {
  final SecureStorageService _secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _appLockEnabled = false;
  bool _hasBiometric = false;
  bool _hasPin = false;
  bool _isLocked = false;
  bool _isSuppressed = false;

  bool get appLockEnabled => _appLockEnabled;
  bool get hasBiometric => _hasBiometric;
  bool get hasPin => _hasPin;
  bool get isLocked => _isLocked;

  SecurityProvider(this._secureStorage) {
    _init();
  }

  Future<void> _init() async {
    _appLockEnabled = await _secureStorage.getAppLockEnabled();
    _hasPin = await _secureStorage.hasPin();
    _hasBiometric = await _checkBiometric();
    if (_appLockEnabled) _isLocked = true;
    notifyListeners();
  }

  Future<bool> _checkBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<void> setAppLockEnabled(bool val) async {
    await _secureStorage.setAppLockEnabled(val);
    _appLockEnabled = val;
    if (!val) _isLocked = false;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.setPin(pin);
    _hasPin = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    return await _secureStorage.verifyPin(pin);
  }

  Future<bool> unlockWithBiometric() async {
    try {
      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Birr Track',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (result) _isLocked = false;
      notifyListeners();
      return result;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await _secureStorage.verifyPin(pin);
    if (ok) {
      _isLocked = false;
      notifyListeners();
    }
    return ok;
  }

  void lock() {
    if (_appLockEnabled && !_isSuppressed) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void suppressLock() => _isSuppressed = true;
  void resumeLock() {
    _isSuppressed = false;
    if (_appLockEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }
}
