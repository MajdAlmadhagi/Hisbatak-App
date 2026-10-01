import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/data/models/app_models.dart';
import 'package:hisbatak_app/domain/entities/transaction_item.dart';

void main() {
  group('Stored dates', () {
    test('TransactionModel saves UTC and reads back the same local time', () {
      final local = DateTime(2026, 10, 2, 12, 15);
      final model = TransactionModel(
        id: 'tx_1',
        title: 'قهوة',
        amount: 28,
        category: 'مطاعم ومقاهي',
        categoryIcon: 'local_cafe',
        paymentMethod: 'Apple Pay',
        dateTime: local,
        type: TransactionType.expense,
        isSynced: false,
      );

      final row = model.toMap();
      expect(row['date_time'], endsWith('Z'));

      final restored = TransactionModel.fromMap(row);
      expect(restored.dateTime.isUtc, isFalse);
      expect(restored.dateTime, local);
    });

    test('GroupModel saves UTC and reads back the same local time', () {
      final local = DateTime(2026, 9, 15, 8, 30);
      final model = GroupModel(
        id: 'grp_1',
        name: 'رحلة أبها',
        type: 'trip',
        iconName: 'hiking',
        memberCount: 3,
        createdAt: local,
      );

      final row = model.toMap();
      expect(row['created_at'], endsWith('Z'));
      expect(GroupModel.fromMap(row).createdAt, local);
    });
  });
}
