import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/utils/id_generator.dart';

void main() {
  group('IdGenerator', () {
    test('uuidV4 produces valid, unique RFC 4122 UUIDs', () {
      final seen = <String>{};
      for (int i = 0; i < 100; i++) {
        final id = IdGenerator.uuidV4();
        expect(IdGenerator.isUuid(id), isTrue, reason: 'Invalid UUID: $id');
        expect(id[14], '4'); // version 4 nibble
        seen.add(id);
      }
      expect(seen.length, 100);
    });

    test('uuidV7 produces valid RFC 9562 time-ordered UUIDs', () {
      final earlier = IdGenerator.uuidV7(DateTime.utc(2026, 1, 1));
      final later = IdGenerator.uuidV7(DateTime.utc(2026, 1, 2));

      expect(IdGenerator.isUuid(earlier), isTrue);
      expect(IdGenerator.isUuid(later), isTrue);
      expect(earlier[14], '7');
      expect(later[14], '7');
      expect(earlier.compareTo(later), lessThan(0));
    });

    test('prefixed appends valid UUIDv7 payload', () {
      final id = IdGenerator.prefixed('tx');
      expect(id.startsWith('tx_'), isTrue);
      expect(IdGenerator.isUuid(id.substring(3)), isTrue);
    });

    test('isUuid rejects non-UUID identifiers like legacy user_me', () {
      expect(IdGenerator.isUuid('user_me'), isFalse);
      expect(IdGenerator.isUuid('tx_123'), isFalse);
      expect(IdGenerator.isUuid(''), isFalse);
      expect(IdGenerator.isUuid(null), isFalse);
    });
  });
}
