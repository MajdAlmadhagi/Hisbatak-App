import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/domain/entities/expense_split_entity.dart';
import 'package:hisbatak_app/core/utils/formatters.dart';

void main() {
  group('Hisbatak Clean Architecture & Strategy Tests', () {
    test('EqualSplitStrategy should split total evenly among members', () {
      final strategy = EqualSplitStrategy();
      final splits = strategy.calculateSplits(
        totalAmount: 240.0,
        memberIds: ['user_me', 'mem_1', 'mem_2'],
        memberNames: {
          'user_me': 'أنت (الدافع)',
          'mem_1': 'خالد العتيبي',
          'mem_2': 'سارة المقرن',
        },
        payerId: 'user_me',
      );

      expect(splits.length, 3);
      expect(splits[0].amount, 80.0);
      expect(splits[0].isPayer, true);
      expect(splits[1].amount, 80.0);
      expect(splits[1].isPayer, false);
      expect(splits[2].amount, 80.0);
      expect(splits[2].isPayer, false);
    });

    test('PercentageSplitStrategy should split based on custom percentages', () {
      final strategy = PercentageSplitStrategy();
      final splits = strategy.calculateSplits(
        totalAmount: 1000.0,
        memberIds: ['m1', 'm2'],
        memberNames: {'m1': 'عضو 1', 'm2': 'عضو 2'},
        payerId: 'm1',
        customValues: {'m1': 60.0, 'm2': 40.0},
      );

      expect(splits.length, 2);
      expect(splits[0].amount, 600.0);
      expect(splits[1].amount, 400.0);
    });

    test('Formatters should format currency correctly with Arabic symbols', () {
      expect(Formatters.formatCurrency(14850.0), '14,850 ر.س');
      expect(Formatters.formatSignedCurrency(2400.0), '+2,400 ر.س');
      expect(Formatters.formatSignedCurrency(-340.0), '-340 ر.س');
      expect(Formatters.formatPercentage(74.2), '74.2%');
    });
  });
}
