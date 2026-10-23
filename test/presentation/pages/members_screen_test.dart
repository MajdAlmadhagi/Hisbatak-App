import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/domain/entities/group_entity.dart';

void main() {
  group('ConsolidatedMemberEntity & Cross-Group Logic Tests', () {
    final groupWork = GroupEntity(
      id: 'grp_work',
      name: 'زملاء العمل',
      type: 'work',
      iconName: 'buildings',
      memberCount: 3,
      createdAt: DateTime.now(),
    );

    final groupHome = GroupEntity(
      id: 'grp_home',
      name: 'سكن الشباب',
      type: 'home',
      iconName: 'home',
      memberCount: 2,
      createdAt: DateTime.now(),
    );

    final groupTrip = GroupEntity(
      id: 'grp_trip',
      name: 'رحلة أبها',
      type: 'trip',
      iconName: 'routing',
      memberCount: 4,
      createdAt: DateTime.now(),
    );

    test('ConsolidatedMemberEntity calculates aggregated balance and identifies groups', () {
      final member = ConsolidatedMemberEntity(
        name: 'خالد العتيبي',
        memberships: [
          const MemberGroupMembership(
            memberId: 'mem_1',
            groupId: 'grp_work',
            groupName: 'زملاء العمل',
            groupType: 'work',
            groupIcon: 'buildings',
            balance: 120.0,
          ),
          const MemberGroupMembership(
            memberId: 'mem_2',
            groupId: 'grp_home',
            groupName: 'سكن الشباب',
            groupType: 'home',
            groupIcon: 'home',
            balance: -50.0,
          ),
        ],
      );

      // Aggregated balance: 120.0 - 50.0 = 70.0 (Owes user net)
      expect(member.totalBalance, equals(70.0));
      expect(member.owesUser, isTrue);
      expect(member.userOwes, isFalse);
      expect(member.isBalanced, isFalse);
      expect(member.groupsCount, equals(2));

      // Verification of group presence
      expect(member.isInGroup('grp_work'), isTrue);
      expect(member.isInGroup('grp_home'), isTrue);
      expect(member.isInGroup('grp_trip'), isFalse);

      // Available groups to join
      final available = member.availableGroups([groupWork, groupHome, groupTrip]);
      expect(available.length, equals(1));
      expect(available.first.id, equals('grp_trip'));
    });

    test('ConsolidatedMemberEntity handles settled/balanced cross-group member', () {
      final member = ConsolidatedMemberEntity(
        name: 'أحمد ناصر',
        memberships: [
          const MemberGroupMembership(
            memberId: 'mem_3',
            groupId: 'grp_work',
            groupName: 'زملاء العمل',
            groupType: 'work',
            groupIcon: 'buildings',
            balance: 0.0,
          ),
        ],
      );

      expect(member.totalBalance, equals(0.0));
      expect(member.isBalanced, isTrue);
      expect(member.owesUser, isFalse);
      expect(member.userOwes, isFalse);
    });

    test('Available groups returns empty when member is already in all groups', () {
      final member = ConsolidatedMemberEntity(
        name: 'فهد الدوسري',
        memberships: [
          const MemberGroupMembership(
            memberId: 'mem_4',
            groupId: 'grp_work',
            groupName: 'زملاء العمل',
            groupType: 'work',
            groupIcon: 'buildings',
            balance: 200.0,
          ),
          const MemberGroupMembership(
            memberId: 'mem_5',
            groupId: 'grp_trip',
            groupName: 'رحلة أبها',
            groupType: 'trip',
            groupIcon: 'routing',
            balance: 0.0,
          ),
        ],
      );

      final available = member.availableGroups([groupWork, groupTrip]);
      expect(available, isEmpty);
    });
  });
}
