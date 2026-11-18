import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_keys.dart';
import '../utils/validators.dart';

/// Contract for local device PIN app lock decoupled from cloud auth identity.
abstract class IAppLockService {
  bool hasPin();
  bool isLockEnabled();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> disableLock({bool clearPin = true});
  Duration? remainingLockout();
  int get failedAttempts;
}

/// Salted, multi-round SHA-256 local PIN lock backed by [SharedPreferences].
class AppLockServiceImpl implements IAppLockService {
  static const int _hashRounds = 2000;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(seconds: 30);

  final SharedPreferences preferences;
  final Random _random;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  AppLockServiceImpl(this.preferences, {Random? random})
      : _random = random ?? Random.secure();

  @override
  int get failedAttempts => _failedAttempts;

  @override
  Duration? remainingLockout() {
    if (_lockedUntil == null) return null;
    final remaining = _lockedUntil!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _lockedUntil = null;
      _failedAttempts = 0;
      return null;
    }
    return remaining;
  }

  @override
  bool hasPin() {
    final hash = preferences.getString(AppKeys.appPinHash);
    final salt = preferences.getString(AppKeys.appPinSalt);
    return hash != null && hash.isNotEmpty && salt != null && salt.isNotEmpty;
  }

  @override
  bool isLockEnabled() {
    return (preferences.getBool(AppKeys.appLockEnabled) ?? false) && hasPin();
  }

  @override
  Future<void> setPin(String pin) async {
    final normalized = Validators.normalizeDigits(pin.trim());
    final validationError = Validators.validatePin(normalized);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final salt = _generateSalt();
    final hash = _hashPin(normalized, salt);

    await preferences.setString(AppKeys.appPinSalt, salt);
    await preferences.setString(AppKeys.appPinHash, hash);
    await preferences.setBool(AppKeys.appLockEnabled, true);
    await preferences.setBool(AppKeys.biometricEnabled, true);
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  @override
  Future<bool> verifyPin(String pin) async {
    if (remainingLockout() != null) {
      return false;
    }

    final storedHash = preferences.getString(AppKeys.appPinHash);
    final storedSalt = preferences.getString(AppKeys.appPinSalt);
    if (storedHash == null ||
        storedHash.isEmpty ||
        storedSalt == null ||
        storedSalt.isEmpty) {
      return false;
    }

    final normalized = Validators.normalizeDigits(pin.trim());
    final candidateHash = _hashPin(normalized, storedSalt);

    if (_constantTimeEquals(storedHash, candidateHash)) {
      _failedAttempts = 0;
      _lockedUntil = null;
      return true;
    }

    _failedAttempts += 1;
    if (_failedAttempts >= _maxFailedAttempts) {
      _lockedUntil = DateTime.now().add(_lockoutDuration);
    }
    return false;
  }

  @override
  Future<void> disableLock({bool clearPin = true}) async {
    await preferences.setBool(AppKeys.appLockEnabled, false);
    await preferences.setBool(AppKeys.biometricEnabled, false);
    if (clearPin) {
      await preferences.remove(AppKeys.appPinHash);
      await preferences.remove(AppKeys.appPinSalt);
    }
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String normalizedPin, String salt) {
    final saltBytes = utf8.encode(salt);
    final pinBytes = utf8.encode(normalizedPin);
    var digest = sha256.convert([...saltBytes, ...pinBytes]);
    for (var i = 1; i < _hashRounds; i++) {
      digest = sha256.convert([...digest.bytes, ...saltBytes]);
    }
    return base64UrlEncode(digest.bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    if (aBytes.length != bBytes.length) return false;
    var diff = 0;
    for (var i = 0; i < aBytes.length; i++) {
      diff |= aBytes[i] ^ bBytes[i];
    }
    return diff == 0;
  }
}
