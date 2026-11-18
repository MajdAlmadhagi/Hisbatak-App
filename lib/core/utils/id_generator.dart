import 'dart:math';

/// [IdGenerator] produces collision-free RFC 4122 / RFC 9562 UUIDs offline
/// using [Random.secure] without requiring server roundtrips.
class IdGenerator {
  static final Random _secureRandom = Random.secure();
  static int _lastMs = -1;
  static int _sequence = 0;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Generates a standard random RFC 4122 UUID v4 string.
  static String uuidV4() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
    return _formatUuid(bytes);
  }

  /// Generates a time-ordered RFC 9562 UUID v7 string (48-bit Unix epoch ms + random).
  static String uuidV7([DateTime? timestamp]) {
    var ms = (timestamp ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    if (ms == _lastMs) {
      _sequence = (_sequence + 1) & 0x0fff;
    } else {
      _lastMs = ms;
      _sequence = _secureRandom.nextInt(4096);
    }

    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    bytes[0] = (ms >> 40) & 0xff;
    bytes[1] = (ms >> 32) & 0xff;
    bytes[2] = (ms >> 24) & 0xff;
    bytes[3] = (ms >> 16) & 0xff;
    bytes[4] = (ms >> 8) & 0xff;
    bytes[5] = ms & 0xff;

    bytes[6] = 0x70 | ((_sequence >> 8) & 0x0f); // version 7
    bytes[7] = _sequence & 0xff;
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
    return _formatUuid(bytes);
  }

  /// Generates a collision-free prefixed ID backed by UUID v7.
  static String prefixed(String prefix) => '${prefix}_${uuidV7()}';

  /// Returns true if [value] matches canonical hyphenated UUID format.
  static bool isUuid(String? value) {
    if (value == null) return false;
    return _uuidRegex.hasMatch(value.trim());
  }

  static String _formatUuid(List<int> bytes) {
    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).join();
    return '${b.substring(0, 8)}-${b.substring(8, 12)}-${b.substring(12, 16)}-${b.substring(16, 20)}-${b.substring(20, 32)}';
  }
}
