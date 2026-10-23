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

    test('TransactionModel serializes foreign keys and reads back joined data correctly', () {
      final local = DateTime(2026, 10, 2, 12, 15);
      final model = TransactionModel(
        id: 'tx_group_1',
        title: 'غداء عمل',
        amount: 250,
        category: 'مطاعم ومقاهي',
        categoryIcon: 'local_cafe',
        paymentMethod: 'فاتورة مشتركة',
        dateTime: local,
        type: TransactionType.expense,
        groupId: 'grp_work',
        expenseId: 'exp_group_1',
        groupName: 'زملاء العمل',
        memberNames: const ['خالد العتيبي', 'سارة الشمري'],
        isSynced: false,
      );

      final row = model.toMap();
      expect(row['group_id'], 'grp_work');
      expect(row['expense_id'], 'exp_group_1');
      // Live joined fields are not stored directly in transactions table
      expect(row.containsKey('group_name'), isFalse);
      expect(row.containsKey('member_names'), isFalse);

      // Deserialization with joined query results
      final restored = TransactionModel.fromMap({
        ...row,
        'group_name': 'زملاء العمل',
        'member_names': 'خالد العتيبي, سارة الشمري',
      });
      expect(restored.groupId, 'grp_work');
      expect(restored.expenseId, 'exp_group_1');
      expect(restored.groupName, 'زملاء العمل');
      expect(restored.hasGroup, isTrue);
      expect(restored.memberNames, ['خالد العتيبي', 'سارة الشمري']);
    });

    test('TransactionModel.fromEntity maps TransactionItem fields completely', () {
      final local = DateTime(2026, 10, 2, 12, 15);
      final item = TransactionItem(
        id: 'tx_item_1',
        title: 'سوبرماركت',
        amount: 150,
        category: 'بقالة وتموين',
        categoryIcon: 'shopping_cart',
        paymentMethod: 'فاتورة مشتركة',
        dateTime: local,
        type: TransactionType.expense,
        groupId: 'grp_work',
        expenseId: 'exp_1',
        groupName: 'زملاء العمل',
        memberNames: const ['خالد العتيبي'],
        isSynced: false,
      );

      final model = TransactionModel.fromEntity(item);
      expect(model.id, item.id);
      expect(model.groupId, 'grp_work');
      expect(model.expenseId, 'exp_1');
      expect(model.groupName, 'زملاء العمل');
      expect(model.memberNames, ['خالد العتيبي']);
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
      expect(row.containsKey('member_count'), isFalse);

      // member_count comes from the query that reads groups.
      final restored = GroupModel.fromMap({...row, 'member_count': 3});
      expect(restored.createdAt, local);
      expect(restored.memberCount, 3);
    });
  });
}
