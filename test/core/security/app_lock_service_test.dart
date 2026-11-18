import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/constants/app_keys.dart';
import 'package:hisbatak_app/core/security/app_lock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late AppLockServiceImpl service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = AppLockServiceImpl(prefs);
  });

  group('AppLockServiceImpl', () {
    test('stores salted SHA-256 PIN hash rather than plaintext', () async {
      await service.setPin('4829');

      expect(service.hasPin(), isTrue);
      expect(service.isLockEnabled(), isTrue);

      final hash = prefs.getString(AppKeys.appPinHash);
      final salt = prefs.getString(AppKeys.appPinSalt);
      expect(hash, isNotNull);
      expect(salt, isNotNull);
      expect(hash, isNot('4829'));
      expect(hash!.contains('4829'), isFalse);
      expect(hash.length, 44); // Base64URL SHA-256 digest length
      expect(base64Url.decode(hash).length, 32);
    });

    test('verifies matching PIN including Arabic numerals and rejects wrong PIN',
        () async {
      await service.setPin('1234');

      expect(await service.verifyPin('1234'), isTrue);
      expect(await service.verifyPin('١٢٣٤'), isTrue);
      expect(await service.verifyPin('9999'), isFalse);
      expect(service.failedAttempts, 1);
    });

    test('triggers lockout after 5 consecutive failed attempts', () async {
      await service.setPin('1234');

      for (int i = 0; i < 5; i++) {
        expect(await service.verifyPin('0000'), isFalse);
      }

      expect(service.failedAttempts, 5);
      expect(service.remainingLockout(), isNotNull);
      // Even correct PIN must be denied while locked out.
      expect(await service.verifyPin('1234'), isFalse);
    });

    test('disableLock clears hash and salt when clearPin is true', () async {
      await service.setPin('1234');
      await service.disableLock(clearPin: true);

      expect(service.isLockEnabled(), isFalse);
      expect(service.hasPin(), isFalse);
      expect(prefs.getString(AppKeys.appPinHash), isNull);
      expect(prefs.getString(AppKeys.appPinSalt), isNull);
    });
  });
}
