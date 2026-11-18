import 'dart:convert';
import 'dart:math' as math;

/// Error correction level for generated ISO/IEC 18004 QR matrices.
enum QrErrorCorrectionLevel {
  low(1), // ~7% recovery
  medium(0), // ~15% recovery
  quartile(3), // ~25% recovery
  high(2); // ~30% recovery

  /// Standard 2-bit format indicator defined by ISO/IEC 18004 Table 12.
  final int formatBits;
  const QrErrorCorrectionLevel(this.formatBits);
}

class _VersionEcSpec {
  final int version;
  final int ecPerBlock;
  final int group1Blocks;
  final int group1Data;
  final int group2Blocks;
  final int group2Data;

  const _VersionEcSpec({
    required this.version,
    required this.ecPerBlock,
    required this.group1Blocks,
    required this.group1Data,
    this.group2Blocks = 0,
    this.group2Data = 0,
  });

  int get totalDataCodewords =>
      (group1Blocks * group1Data) + (group2Blocks * group2Data);

  int get totalCodewords =>
      totalDataCodewords + ((group1Blocks + group2Blocks) * ecPerBlock);
}

/// Pure-Dart ISO/IEC 18004 QR Code generator supporting Versions 1–9 in Byte
/// mode (UTF-8), Reed-Solomon error correction over GF(256), alignment
/// patterns, format/version BCH coding, and 8-mask penalty evaluation.
class QrMatrixGenerator {
  QrMatrixGenerator._();

  /// Encodes [data] into a square boolean matrix (`true` = dark module).
  ///
  /// Defaults to [QrErrorCorrectionLevel.high] (~30% error recovery), making
  /// the resulting QR code resilient to a centered brand emblem while automatically
  /// stepping down to lower ECC levels only if needed to fit long payloads.
  static List<List<bool>> generate(
    String data, {
    QrErrorCorrectionLevel errorCorrection = QrErrorCorrectionLevel.high,
  }) {
    final payloadBytes = utf8.encode(data);
    final selected = _selectSpec(payloadBytes.length, errorCorrection);
    final version = selected.$1.version;
    final spec = selected.$1;
    final ecLevel = selected.$2;

    final dataCodewords = _buildDataCodewords(payloadBytes, spec);
    final finalCodewords = _interleaveWithEcc(dataCodewords, spec);

    final size = version * 4 + 17;
    final matrix = List.generate(size, (_) => List<bool>.filled(size, false));
    final isFunction = List.generate(
      size,
      (_) => List<bool>.filled(size, false),
    );

    _drawFunctionPatterns(matrix, isFunction, version, size);
    _placeCodewords(matrix, isFunction, finalCodewords, size);

    int bestMask = 0;
    int bestPenalty = 1 << 30;
    List<List<bool>>? bestMatrix;

    for (int mask = 0; mask < 8; mask++) {
      final candidate = List.generate(
        size,
        (r) => List<bool>.from(matrix[r]),
      );
      _applyMask(candidate, isFunction, mask, size);
      _drawFormatInfo(candidate, ecLevel, mask, size);
      if (version >= 7) {
        _drawVersionInfo(candidate, version, size);
      }

      final penalty = _evaluatePenalty(candidate, size);
      if (penalty < bestPenalty) {
        bestPenalty = penalty;
        bestMask = mask;
        bestMatrix = candidate;
      }
    }

    if (bestMatrix != null) {
      return bestMatrix;
    }

    _applyMask(matrix, isFunction, bestMask, size);
    _drawFormatInfo(matrix, ecLevel, bestMask, size);
    if (version >= 7) {
      _drawVersionInfo(matrix, version, size);
    }
    return matrix;
  }

  static (_VersionEcSpec, QrErrorCorrectionLevel) _selectSpec(
    int byteLength,
    QrErrorCorrectionLevel preferred,
  ) {
    final fallbackOrder = <QrErrorCorrectionLevel>[
      preferred,
      if (preferred != QrErrorCorrectionLevel.quartile)
        QrErrorCorrectionLevel.quartile,
      if (preferred != QrErrorCorrectionLevel.medium)
        QrErrorCorrectionLevel.medium,
      if (preferred != QrErrorCorrectionLevel.low) QrErrorCorrectionLevel.low,
    ];

    for (final level in fallbackOrder) {
      final specs = _ecSpecsByLevel[level]!;
      for (final spec in specs) {
        // Versions 1-9 use 4-bit mode + 8-bit length header = 12 bits (+4 terminator)
        final requiredBits = 4 + 8 + (byteLength * 8);
        if (requiredBits <= spec.totalDataCodewords * 8) {
          return (spec, level);
        }
      }
    }

    throw ArgumentError(
      'Payload length ($byteLength bytes) exceeds supported QR Versions 1-9.',
    );
  }

  static List<int> _buildDataCodewords(
    List<int> payloadBytes,
    _VersionEcSpec spec,
  ) {
    final bits = <int>[];

    void appendBits(int value, int bitCount) {
      for (int i = bitCount - 1; i >= 0; i--) {
        bits.add((value >> i) & 1);
      }
    }

    // Mode indicator: Byte mode (0100)
    appendBits(0x4, 4);
    // Character count indicator (8 bits for versions 1-9)
    appendBits(payloadBytes.length, 8);
    // Data payload
    for (final b in payloadBytes) {
      appendBits(b, 8);
    }

    final maxBits = spec.totalDataCodewords * 8;
    // Terminator (up to 4 zero bits)
    final terminatorLen = math.min(4, maxBits - bits.length);
    for (int i = 0; i < terminatorLen; i++) {
      bits.add(0);
    }

    // Pad to byte boundary
    while (bits.length % 8 != 0) {
      bits.add(0);
    }

    final codewords = <int>[];
    for (int i = 0; i < bits.length; i += 8) {
      int byte = 0;
      for (int j = 0; j < 8; j++) {
        byte = (byte << 1) | bits[i + j];
      }
      codewords.add(byte);
    }

    // Alternate pad codewords 0xEC and 0x11
    const padBytes = [0xEC, 0x11];
    int padIndex = 0;
    while (codewords.length < spec.totalDataCodewords) {
      codewords.add(padBytes[padIndex % 2]);
      padIndex++;
    }

    return codewords;
  }

  static List<int> _interleaveWithEcc(
    List<int> dataCodewords,
    _VersionEcSpec spec,
  ) {
    final dataBlocks = <List<int>>[];
    final ecBlocks = <List<int>>[];
    final generator = _ReedSolomon.generatorPoly(spec.ecPerBlock);

    int offset = 0;
    void addBlocks(int count, int dataLen) {
      for (int i = 0; i < count; i++) {
        final block = dataCodewords.sublist(offset, offset + dataLen);
        offset += dataLen;
        dataBlocks.add(block);
        ecBlocks.add(_ReedSolomon.computeRemainder(block, generator));
      }
    }

    addBlocks(spec.group1Blocks, spec.group1Data);
    addBlocks(spec.group2Blocks, spec.group2Data);

    final result = <int>[];
    final maxDataLen = math.max(spec.group1Data, spec.group2Data);
    for (int i = 0; i < maxDataLen; i++) {
      for (final block in dataBlocks) {
        if (i < block.length) {
          result.add(block[i]);
        }
      }
    }

    for (int i = 0; i < spec.ecPerBlock; i++) {
      for (final ec in ecBlocks) {
        result.add(ec[i]);
      }
    }

    return result;
  }

  static void _drawFunctionPatterns(
    List<List<bool>> matrix,
    List<List<bool>> isFunction,
    int version,
    int size,
  ) {
    // 1. Finder patterns + 1-module separators
    _drawFinderPattern(matrix, isFunction, 0, 0, size);
    _drawFinderPattern(matrix, isFunction, 0, size - 7, size);
    _drawFinderPattern(matrix, isFunction, size - 7, 0, size);

    // 2. Alignment patterns
    final alignCoords = _alignmentCenters[version] ?? const <int>[];
    for (final r in alignCoords) {
      for (final c in alignCoords) {
        // Skip overlaps with the three finder corners
        final overlapsTopLeft = r <= 8 && c <= 8;
        final overlapsTopRight = r <= 8 && c >= size - 9;
        final overlapsBottomLeft = r >= size - 9 && c <= 8;
        if (overlapsTopLeft || overlapsTopRight || overlapsBottomLeft) {
          continue;
        }
        _drawAlignmentPattern(matrix, isFunction, r, c);
      }
    }

    // 3. Timing patterns
    for (int i = 8; i < size - 8; i++) {
      final isDark = i.isEven;
      matrix[6][i] = isDark;
      isFunction[6][i] = true;
      matrix[i][6] = isDark;
      isFunction[i][6] = true;
    }

    // 4. Dark module & format reserve
    matrix[size - 8][8] = true;
    isFunction[size - 8][8] = true;

    for (int i = 0; i < 9; i++) {
      if (i != 6) {
        isFunction[8][i] = true;
        isFunction[i][8] = true;
      }
    }
    for (int i = size - 8; i < size; i++) {
      isFunction[8][i] = true;
      if (i != size - 8) {
        isFunction[i][8] = true;
      }
    }

    // 5. Version info reserve (version >= 7)
    if (version >= 7) {
      for (int i = 0; i < 6; i++) {
        for (int j = size - 11; j < size - 8; j++) {
          isFunction[i][j] = true;
          isFunction[j][i] = true;
        }
      }
    }
  }

  static void _drawFinderPattern(
    List<List<bool>> matrix,
    List<List<bool>> isFunction,
    int top,
    int left,
    int size,
  ) {
    for (int dr = -1; dr <= 7; dr++) {
      for (int dc = -1; dc <= 7; dc++) {
        final r = top + dr;
        final c = left + dc;
        if (r < 0 || r >= size || c < 0 || c >= size) continue;

        final inOuter = dr >= 0 && dr <= 6 && dc >= 0 && dc <= 6;
        final onOuterBorder = dr == 0 || dr == 6 || dc == 0 || dc == 6;
        final inInnerCenter = dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4;

        matrix[r][c] = inOuter && (onOuterBorder || inInnerCenter);
        isFunction[r][c] = true;
      }
    }
  }

  static void _drawAlignmentPattern(
    List<List<bool>> matrix,
    List<List<bool>> isFunction,
    int centerRow,
    int centerCol,
  ) {
    for (int dr = -2; dr <= 2; dr++) {
      for (int dc = -2; dc <= 2; dc++) {
        final r = centerRow + dr;
        final c = centerCol + dc;
        final dist = math.max(dr.abs(), dc.abs());
        matrix[r][c] = dist == 2 || dist == 0;
        isFunction[r][c] = true;
      }
    }
  }

  static void _placeCodewords(
    List<List<bool>> matrix,
    List<List<bool>> isFunction,
    List<int> codewords,
    int size,
  ) {
    int bitIndex = 0;
    final totalBits = codewords.length * 8;
    bool goingUp = true;

    for (int right = size - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5;

      for (int step = 0; step < size; step++) {
        final row = goingUp ? (size - 1 - step) : step;
        for (int offset = 0; offset < 2; offset++) {
          final col = right - offset;
          if (isFunction[row][col]) continue;

          bool dark = false;
          if (bitIndex < totalBits) {
            final byte = codewords[bitIndex >> 3];
            dark = ((byte >> (7 - (bitIndex & 7))) & 1) == 1;
            bitIndex++;
          }
          matrix[row][col] = dark;
        }
      }
      goingUp = !goingUp;
    }
  }

  static void _applyMask(
    List<List<bool>> matrix,
    List<List<bool>> isFunction,
    int mask,
    int size,
  ) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (isFunction[r][c]) continue;
        if (_maskPredicate(mask, r, c)) {
          matrix[r][c] = !matrix[r][c];
        }
      }
    }
  }

  static bool _maskPredicate(int mask, int r, int c) {
    switch (mask) {
      case 0:
        return (r + c) % 2 == 0;
      case 1:
        return r % 2 == 0;
      case 2:
        return c % 3 == 0;
      case 3:
        return (r + c) % 3 == 0;
      case 4:
        return ((r ~/ 2) + (c ~/ 3)) % 2 == 0;
      case 5:
        return ((r * c) % 2) + ((r * c) % 3) == 0;
      case 6:
        return (((r * c) % 2) + ((r * c) % 3)) % 2 == 0;
      case 7:
        return (((r + c) % 2) + ((r * c) % 3)) % 2 == 0;
      default:
        return false;
    }
  }

  static void _drawFormatInfo(
    List<List<bool>> matrix,
    QrErrorCorrectionLevel level,
    int mask,
    int size,
  ) {
    final data = (level.formatBits << 3) | mask;
    int rem = data << 10;
    const gen = 0x537;
    for (int bit = 14; bit >= 10; bit--) {
      if (((rem >> bit) & 1) != 0) {
        rem ^= gen << (bit - 10);
      }
    }
    final formatBits = ((data << 10) | rem) ^ 0x5412;

    for (int i = 0; i < 15; i++) {
      final isDark = ((formatBits >> i) & 1) == 1;

      // Vertical TL copy (bits 0..7 -> rows 0..5, 7, 8 at col 8)
      // Horizontal TL copy (bits 8..14 -> cols 7, 5..0 at row 8, skipping timing col 6)
      if (i < 6) {
        matrix[i][8] = isDark;
      } else if (i < 8) {
        matrix[i + 1][8] = isDark;
      } else if (i == 8) {
        matrix[8][7] = isDark;
      } else {
        matrix[8][14 - i] = isDark;
      }

      // Split TR/BL copy
      if (i < 8) {
        matrix[8][size - 1 - i] = isDark;
      } else {
        matrix[size - 15 + i][8] = isDark;
      }
    }
  }

  static void _drawVersionInfo(
    List<List<bool>> matrix,
    int version,
    int size,
  ) {
    int rem = version << 12;
    const gen = 0x1F25;
    for (int bit = 17; bit >= 12; bit--) {
      if (((rem >> bit) & 1) != 0) {
        rem ^= gen << (bit - 12);
      }
    }
    final verBits = (version << 12) | rem;

    for (int i = 0; i < 18; i++) {
      final isDark = ((verBits >> i) & 1) == 1;
      final a = i ~/ 3;
      final b = (i % 3) + size - 11;
      matrix[b][a] = isDark;
      matrix[a][b] = isDark;
    }
  }

  static int _evaluatePenalty(List<List<bool>> matrix, int size) {
    int penalty = 0;

    // Rule 1 & Rule 3 helper for rows and columns
    for (int i = 0; i < size; i++) {
      int rowRun = 1;
      int colRun = 1;
      for (int j = 1; j < size; j++) {
        if (matrix[i][j] == matrix[i][j - 1]) {
          rowRun++;
        } else {
          if (rowRun >= 5) penalty += 3 + (rowRun - 5);
          rowRun = 1;
        }
        if (matrix[j][i] == matrix[j - 1][i]) {
          colRun++;
        } else {
          if (colRun >= 5) penalty += 3 + (colRun - 5);
          colRun = 1;
        }
      }
      if (rowRun >= 5) penalty += 3 + (rowRun - 5);
      if (colRun >= 5) penalty += 3 + (colRun - 5);
    }

    // Rule 2: 2x2 blocks of identical color
    for (int r = 0; r < size - 1; r++) {
      for (int c = 0; c < size - 1; c++) {
        final v = matrix[r][c];
        if (matrix[r][c + 1] == v &&
            matrix[r + 1][c] == v &&
            matrix[r + 1][c + 1] == v) {
          penalty += 3;
        }
      }
    }

    // Rule 3: Finder-like 1:1:3:1:1 patterns followed/preceded by 4 light modules
    bool matchesPattern(List<bool> line, int start, List<bool> pattern) {
      for (int k = 0; k < pattern.length; k++) {
        if (line[start + k] != pattern[k]) return false;
      }
      return true;
    }

    const p1 = [
      true,
      false,
      true,
      true,
      true,
      false,
      true,
      false,
      false,
      false,
      false,
    ];
    const p2 = [
      false,
      false,
      false,
      false,
      true,
      false,
      true,
      true,
      true,
      false,
      true,
    ];

    for (int i = 0; i < size; i++) {
      final row = matrix[i];
      final col = List<bool>.generate(size, (r) => matrix[r][i]);
      for (int s = 0; s <= size - 11; s++) {
        if (matchesPattern(row, s, p1) || matchesPattern(row, s, p2)) {
          penalty += 40;
        }
        if (matchesPattern(col, s, p1) || matchesPattern(col, s, p2)) {
          penalty += 40;
        }
      }
    }

    // Rule 4: Dark/light ratio balance
    int darkCount = 0;
    for (final row in matrix) {
      for (final cell in row) {
        if (cell) darkCount++;
      }
    }
    final total = size * size;
    final pct = (darkCount * 100) ~/ total;
    final prev5 = (pct ~/ 5) * 5;
    final next5 = prev5 + 5;
    final k = math.min((prev5 - 50).abs(), (next5 - 50).abs()) ~/ 5;
    penalty += k * 10;

    return penalty;
  }

  static const Map<int, List<int>> _alignmentCenters = {
    1: [],
    2: [6, 18],
    3: [6, 22],
    4: [6, 26],
    5: [6, 30],
    6: [6, 34],
    7: [6, 22, 38],
    8: [6, 24, 42],
    9: [6, 26, 46],
  };

  static const Map<QrErrorCorrectionLevel, List<_VersionEcSpec>> _ecSpecsByLevel =
      {
    QrErrorCorrectionLevel.low: [
      _VersionEcSpec(version: 1, ecPerBlock: 7, group1Blocks: 1, group1Data: 19),
      _VersionEcSpec(
          version: 2, ecPerBlock: 10, group1Blocks: 1, group1Data: 34),
      _VersionEcSpec(
          version: 3, ecPerBlock: 15, group1Blocks: 1, group1Data: 55),
      _VersionEcSpec(
          version: 4, ecPerBlock: 20, group1Blocks: 1, group1Data: 80),
      _VersionEcSpec(
          version: 5, ecPerBlock: 26, group1Blocks: 1, group1Data: 108),
      _VersionEcSpec(
          version: 6, ecPerBlock: 18, group1Blocks: 2, group1Data: 68),
      _VersionEcSpec(
          version: 7, ecPerBlock: 20, group1Blocks: 2, group1Data: 78),
      _VersionEcSpec(
          version: 8, ecPerBlock: 24, group1Blocks: 2, group1Data: 97),
      _VersionEcSpec(
          version: 9, ecPerBlock: 30, group1Blocks: 2, group1Data: 116),
    ],
    QrErrorCorrectionLevel.medium: [
      _VersionEcSpec(
          version: 1, ecPerBlock: 10, group1Blocks: 1, group1Data: 16),
      _VersionEcSpec(
          version: 2, ecPerBlock: 16, group1Blocks: 1, group1Data: 28),
      _VersionEcSpec(
          version: 3, ecPerBlock: 26, group1Blocks: 1, group1Data: 44),
      _VersionEcSpec(
          version: 4, ecPerBlock: 18, group1Blocks: 2, group1Data: 32),
      _VersionEcSpec(
          version: 5, ecPerBlock: 24, group1Blocks: 2, group1Data: 43),
      _VersionEcSpec(
          version: 6, ecPerBlock: 16, group1Blocks: 4, group1Data: 27),
      _VersionEcSpec(
          version: 7, ecPerBlock: 18, group1Blocks: 4, group1Data: 31),
      _VersionEcSpec(
        version: 8,
        ecPerBlock: 22,
        group1Blocks: 2,
        group1Data: 38,
        group2Blocks: 2,
        group2Data: 39,
      ),
      _VersionEcSpec(
        version: 9,
        ecPerBlock: 22,
        group1Blocks: 3,
        group1Data: 36,
        group2Blocks: 2,
        group2Data: 37,
      ),
    ],
    QrErrorCorrectionLevel.quartile: [
      _VersionEcSpec(
          version: 1, ecPerBlock: 13, group1Blocks: 1, group1Data: 13),
      _VersionEcSpec(
          version: 2, ecPerBlock: 22, group1Blocks: 1, group1Data: 22),
      _VersionEcSpec(
          version: 3, ecPerBlock: 18, group1Blocks: 2, group1Data: 17),
      _VersionEcSpec(
          version: 4, ecPerBlock: 26, group1Blocks: 2, group1Data: 24),
      _VersionEcSpec(
        version: 5,
        ecPerBlock: 18,
        group1Blocks: 2,
        group1Data: 15,
        group2Blocks: 2,
        group2Data: 16,
      ),
      _VersionEcSpec(
          version: 6, ecPerBlock: 24, group1Blocks: 4, group1Data: 19),
      _VersionEcSpec(
        version: 7,
        ecPerBlock: 18,
        group1Blocks: 2,
        group1Data: 14,
        group2Blocks: 4,
        group2Data: 15,
      ),
      _VersionEcSpec(
        version: 8,
        ecPerBlock: 22,
        group1Blocks: 4,
        group1Data: 18,
        group2Blocks: 2,
        group2Data: 19,
      ),
      _VersionEcSpec(
        version: 9,
        ecPerBlock: 20,
        group1Blocks: 4,
        group1Data: 16,
        group2Blocks: 4,
        group2Data: 17,
      ),
    ],
    QrErrorCorrectionLevel.high: [
      _VersionEcSpec(
          version: 1, ecPerBlock: 17, group1Blocks: 1, group1Data: 9),
      _VersionEcSpec(
          version: 2, ecPerBlock: 28, group1Blocks: 1, group1Data: 16),
      _VersionEcSpec(
          version: 3, ecPerBlock: 22, group1Blocks: 2, group1Data: 13),
      _VersionEcSpec(
          version: 4, ecPerBlock: 16, group1Blocks: 4, group1Data: 9),
      _VersionEcSpec(
        version: 5,
        ecPerBlock: 22,
        group1Blocks: 2,
        group1Data: 11,
        group2Blocks: 2,
        group2Data: 12,
      ),
      _VersionEcSpec(
          version: 6, ecPerBlock: 28, group1Blocks: 4, group1Data: 15),
      _VersionEcSpec(
        version: 7,
        ecPerBlock: 26,
        group1Blocks: 4,
        group1Data: 13,
        group2Blocks: 1,
        group2Data: 14,
      ),
      _VersionEcSpec(
        version: 8,
        ecPerBlock: 26,
        group1Blocks: 4,
        group1Data: 14,
        group2Blocks: 2,
        group2Data: 15,
      ),
      _VersionEcSpec(
        version: 9,
        ecPerBlock: 24,
        group1Blocks: 4,
        group1Data: 12,
        group2Blocks: 4,
        group2Data: 13,
      ),
    ],
  };
}

class _ReedSolomon {
  static final List<int> _exp = List<int>.filled(512, 0);
  static final List<int> _log = List<int>.filled(256, 0);
  static bool _initialized = false;

  static void _ensureInit() {
    if (_initialized) return;
    int x = 1;
    for (int i = 0; i < 255; i++) {
      _exp[i] = x;
      _log[x] = i;
      x <<= 1;
      if ((x & 0x100) != 0) {
        x ^= 0x11D;
      }
    }
    for (int i = 255; i < 512; i++) {
      _exp[i] = _exp[i - 255];
    }
    _initialized = true;
  }

  static int _mul(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return _exp[_log[a] + _log[b]];
  }

  static List<int> _polyMul(List<int> p, List<int> q) {
    final result = List<int>.filled(p.length + q.length - 1, 0);
    for (int j = 0; j < q.length; j++) {
      for (int i = 0; i < p.length; i++) {
        result[i + j] ^= _mul(p[i], q[j]);
      }
    }
    return result;
  }

  static List<int> generatorPoly(int degree) {
    _ensureInit();
    var poly = <int>[1];
    for (int i = 0; i < degree; i++) {
      poly = _polyMul(poly, [1, _exp[i]]);
    }
    return poly;
  }

  static List<int> computeRemainder(List<int> data, List<int> generator) {
    _ensureInit();
    final degree = generator.length - 1;
    final work = List<int>.filled(data.length + degree, 0);
    work.setRange(0, data.length, data);

    for (int i = 0; i < data.length; i++) {
      final factor = work[i];
      if (factor == 0) continue;
      for (int j = 0; j < generator.length; j++) {
        work[i + j] ^= _mul(generator[j], factor);
      }
    }

    return work.sublist(data.length);
  }
}
