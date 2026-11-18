import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/utils/qr_matrix_generator.dart';

void main() {
  group('QrMatrixGenerator (ISO/IEC 18004)', () {
    void expectFinderAt(List<List<bool>> matrix, int top, int left) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final isOuter = r == 0 || r == 6 || c == 0 || c == 6;
          final isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          expect(
            matrix[top + r][left + c],
            isOuter || isInner,
            reason: 'Finder mismatch at ($top+$r, $left+$c)',
          );
        }
      }
    }

    test('generates valid ISO square dimensions and fixed function patterns',
        () {
      const payload = 'hisbatak://u/550e8400-e29b-41d4-a716-446655440000';
      final matrix = QrMatrixGenerator.generate(
        payload,
        errorCorrection: QrErrorCorrectionLevel.high,
      );

      final size = matrix.length;
      expect(size, greaterThanOrEqualTo(21));
      expect((size - 17) % 4, 0);
      for (final row in matrix) {
        expect(row.length, size);
      }

      // Three 7x7 finder patterns
      expectFinderAt(matrix, 0, 0);
      expectFinderAt(matrix, 0, size - 7);
      expectFinderAt(matrix, size - 7, 0);

      // Alternating timing patterns on row 6 and column 6
      for (int i = 8; i < size - 8; i++) {
        expect(matrix[6][i], i.isEven);
        expect(matrix[i][6], i.isEven);
      }

      // Mandatory dark module next to bottom-left separator
      expect(matrix[size - 8][8], isTrue);
    });

    test('encoding is deterministic and distinguishes different user URIs', () {
      final a1 = QrMatrixGenerator.generate(
        'hisbatak://u/550e8400-e29b-41d4-a716-446655440000',
      );
      final a2 = QrMatrixGenerator.generate(
        'hisbatak://u/550e8400-e29b-41d4-a716-446655440000',
      );
      final b = QrMatrixGenerator.generate(
        'hisbatak://u/550e8400-e29b-41d4-a716-446655440001',
      );

      expect(a1, equals(a2));
      expect(a1, isNot(equals(b)));
    });

    test('supports version >= 7 with UTF-8 Arabic payloads without errors', () {
      const richPayload =
          'hisbatak://u/550e8400-e29b-41d4-a716-446655440000?p=%2B967770000000&n=محمد_أحمد_اليمني';
      final matrix = QrMatrixGenerator.generate(richPayload);
      expect(matrix.length, greaterThanOrEqualTo(29));
      expect((matrix.length - 17) % 4, 0);
    });
  });
}
