import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/utils/validators.dart';

void main() {
  group('Validators phone normalization & PIN rules', () {
    test('normalizeDigits converts Arabic and Persian numerals to ASCII', () {
      expect(Validators.normalizeDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(Validators.normalizeDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('tryNormalizePhoneE164 normalizes Yemeni formats', () {
      expect(Validators.tryNormalizePhoneE164('770000000'), '+967770000000');
      expect(Validators.tryNormalizePhoneE164('0770000000'), '+967770000000');
      expect(
        Validators.tryNormalizePhoneE164('967 770 000 000'),
        '+967770000000',
      );
      expect(
        Validators.tryNormalizePhoneE164('٧٧٠-٠٠٠-٠٠٠'),
        '+967770000000',
      );
    });

    test('tryNormalizePhoneE164 normalizes Saudi and international numbers', () {
      expect(Validators.tryNormalizePhoneE164('0501234567'), '+966501234567');
      expect(Validators.tryNormalizePhoneE164('501234567'), '+966501234567');
      expect(
        Validators.tryNormalizePhoneE164('001 (415) 555-2671'),
        '+14155552671',
      );
      expect(
        Validators.tryNormalizePhoneE164('+44 7911 123456'),
        '+447911123456',
      );
    });

    test('tryNormalizePhoneE164 rejects empty or invalid inputs', () {
      expect(Validators.tryNormalizePhoneE164(null), isNull);
      expect(Validators.tryNormalizePhoneE164(''), isNull);
      expect(Validators.tryNormalizePhoneE164('12345'), isNull);
      expect(Validators.tryNormalizePhoneE164('abc'), isNull);
    });

    test('validatePhone allows optional empty input unless isRequired is true',
        () {
      expect(Validators.validatePhone(''), isNull);
      expect(Validators.validatePhone('', isRequired: true), isNotNull);
      expect(Validators.validatePhone('770000000', isRequired: true), isNull);
      expect(Validators.validatePhone('123'), isNotNull);
    });

    test('validatePin validates 4-digit PINs including Arabic numerals', () {
      expect(Validators.validatePin('1234'), isNull);
      expect(Validators.validatePin('١٢٣٤'), isNull);
      expect(Validators.validatePin('123'), isNotNull);
      expect(Validators.validatePin('12ab'), isNotNull);
    });
  });
}
