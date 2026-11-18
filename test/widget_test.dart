import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/utils/formatters.dart';
import 'package:hisbatak_app/domain/entities/expense_split_entity.dart';

void main() {
  group('Hisbatak Clean Architecture & Strategy Tests', () {
    test('EqualSplitStrategy should split total evenly among members', () {
      final strategy = EqualSplitStrategy();
      final splits = strategy.calculateSplits(
        totalAmount: 240.0,
        memberIds: ['user_uuid', 'mem_1', 'mem_2'],
        memberNames: {
          'user_uuid': 'أنت (الدافع)',
          'mem_1': 'خالد العتيبي',
          'mem_2': 'سارة المقرن',
        },
        payerId: 'user_uuid',
      );

      expect(splits.length, 3);
      expect(splits[0].amount, 80.0);
      expect(splits[0].isPayer, true);
      expect(splits[1].amount, 80.0);
      expect(splits[1].isPayer, false);
      expect(splits[2].amount, 80.0);
      expect(splits[2].isPayer, false);

      final totalSplit = splits.fold<double>(0.0, (s, e) => s + e.amount);
      expect(totalSplit, closeTo(240.0, 0.01));
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
      expect(splits[0].isPayer, isTrue);
      expect(splits[1].isPayer, isFalse);
    });

    test('CustomAmountSplitStrategy should assign exact custom amounts', () {
      final strategy = CustomAmountSplitStrategy();
      final splits = strategy.calculateSplits(
        totalAmount: 250.0,
        memberIds: ['m1', 'm2', 'm3'],
        memberNames: {'m1': 'عضو 1', 'm2': 'عضو 2', 'm3': 'عضو 3'},
        payerId: 'm1',
        customValues: {'m1': 100.0, 'm2': 100.0, 'm3': 50.0},
      );

      expect(splits.length, 3);
      expect(splits[0].amount, 100.0);
      expect(splits[0].percentage, 40.0);
      expect(splits[1].amount, 100.0);
      expect(splits[1].percentage, 40.0);
      expect(splits[2].amount, 50.0);
      expect(splits[2].percentage, 20.0);
    });

    test(
        'EqualSplitStrategy handles third-party payer where current user owes share',
        () {
      final strategy = EqualSplitStrategy();
      final splits = strategy.calculateSplits(
        totalAmount: 300.0,
        memberIds: ['user_uuid', 'friend_1', 'friend_2'],
        memberNames: {
          'user_uuid': 'أنت',
          'friend_1': 'طارق',
          'friend_2': 'ماجد',
        },
        payerId: 'friend_1',
      );

      final userSplit = splits.firstWhere((s) => s.memberId == 'user_uuid');
      final payerSplit = splits.firstWhere((s) => s.memberId == 'friend_1');

      expect(userSplit.isPayer, isFalse);
      expect(userSplit.amount, closeTo(100.0, 0.01));
      expect(payerSplit.isPayer, isTrue);
      expect(payerSplit.amount, closeTo(100.0, 0.01));
    });

    test('Formatters should format currency correctly with Arabic symbols', () {
      expect(Formatters.formatCurrency(14850.0), '14,850 ر.س');
      expect(Formatters.formatSignedCurrency(2400.0), '+2,400 ر.س');
      expect(Formatters.formatSignedCurrency(-340.0), '-340 ر.س');
      expect(Formatters.formatPercentage(74.2), '74.2%');
    });
  });
}
