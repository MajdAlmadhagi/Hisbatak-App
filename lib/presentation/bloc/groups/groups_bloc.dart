import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/expense_split_entity.dart';
import '../../../domain/usecases/groups/group_usecases.dart';

// EVENTS
abstract class GroupsEvent extends Equatable {
  const GroupsEvent();
  @override
  List<Object?> get props => [];
}

class LoadGroupsEvent extends GroupsEvent {}

class SelectGroupEvent extends GroupsEvent {
  final String groupId;
  const SelectGroupEvent(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class AddSharedExpenseEvent extends GroupsEvent {
  final GroupExpense expense;
  const AddSharedExpenseEvent(this.expense);
  @override
  List<Object?> get props => [expense];
}

class AddGroupMemberEvent extends GroupsEvent {
  final GroupMemberEntity member;
  const AddGroupMemberEvent(this.member);
  @override
  List<Object?> get props => [member];
}

class AddGroupEvent extends GroupsEvent {
  final GroupEntity group;
  const AddGroupEvent(this.group);
  @override
  List<Object?> get props => [group];
}

class CreateGroupWithMembersEvent extends GroupsEvent {
  final GroupEntity group;
  final List<GroupMemberEntity> members;
  const CreateGroupWithMembersEvent({
    required this.group,
    this.members = const [],
  });
  @override
  List<Object?> get props => [group, members];
}

class SettleMemberEvent extends GroupsEvent {
  final String memberId;
  final String groupId;
  const SettleMemberEvent({required this.memberId, required this.groupId});
  @override
  List<Object?> get props => [memberId, groupId];
}

class AddExistingMemberToGroupEvent extends GroupsEvent {
  final String memberName;
  final String? avatarUrl;
  final String targetGroupId;
  final String? note;

  const AddExistingMemberToGroupEvent({
    required this.memberName,
    this.avatarUrl,
    required this.targetGroupId,
    this.note,
  });

  @override
  List<Object?> get props => [memberName, avatarUrl, targetGroupId, note];
}

// STATES
abstract class GroupsState extends Equatable {
  const GroupsState();
  @override
  List<Object?> get props => [];
}

class GroupsInitial extends GroupsState {}

class GroupsLoading extends GroupsState {}

class GroupsLoaded extends GroupsState {
  final List<GroupEntity> groups;
  final String selectedGroupId;
  final List<GroupMemberEntity> activeMembers;
  final DebtSummary debtSummary;
  final List<ConsolidatedMemberEntity> allMembers;

  const GroupsLoaded({
    required this.groups,
    required this.selectedGroupId,
    required this.activeMembers,
    required this.debtSummary,
    this.allMembers = const [],
  });

  GroupEntity? get selectedGroup {
    try {
      return groups.firstWhere((g) => g.id == selectedGroupId);
    } catch (_) {
      return groups.isNotEmpty ? groups.first : null;
    }
  }

  GroupsLoaded copyWith({
    List<GroupEntity>? groups,
    String? selectedGroupId,
    List<GroupMemberEntity>? activeMembers,
    DebtSummary? debtSummary,
    List<ConsolidatedMemberEntity>? allMembers,
  }) {
    return GroupsLoaded(
      groups: groups ?? this.groups,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      activeMembers: activeMembers ?? this.activeMembers,
      debtSummary: debtSummary ?? this.debtSummary,
      allMembers: allMembers ?? this.allMembers,
    );
  }

  @override
  List<Object?> get props => [
        groups,
        selectedGroupId,
        activeMembers,
        debtSummary,
        allMembers,
      ];
}

class GroupsError extends GroupsState {
  final String message;
  const GroupsError(this.message);
  @override
  List<Object?> get props => [message];
}

/// [GroupsBloc] manages collaborative bill splitting groups, members, debt calculations, and settlements.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  final GetGroupsUseCase getGroupsUseCase;
  final GetGroupMembersUseCase getGroupMembersUseCase;
  final GetDebtSummaryUseCase getDebtSummaryUseCase;
  final AddGroupExpenseUseCase addGroupExpenseUseCase;
  final AddGroupMemberUseCase addGroupMemberUseCase;
  final AddGroupUseCase addGroupUseCase;
  final SettleBalanceUseCase settleBalanceUseCase;
  final GetConsolidatedMembersUseCase getConsolidatedMembersUseCase;

  GroupsBloc({
    required this.getGroupsUseCase,
    required this.getGroupMembersUseCase,
    required this.getDebtSummaryUseCase,
    required this.addGroupExpenseUseCase,
    required this.addGroupMemberUseCase,
    required this.addGroupUseCase,
    required this.settleBalanceUseCase,
    required this.getConsolidatedMembersUseCase,
  }) : super(GroupsInitial()) {
    on<LoadGroupsEvent>(_onLoadGroups);
    on<SelectGroupEvent>(_onSelectGroup);
    on<AddSharedExpenseEvent>(_onAddSharedExpense);
    on<AddGroupMemberEvent>(_onAddGroupMember);
    on<AddExistingMemberToGroupEvent>(_onAddExistingMemberToGroup);
    on<AddGroupEvent>(_onAddGroup);
    on<CreateGroupWithMembersEvent>(_onCreateGroupWithMembers);
    on<SettleMemberEvent>(_onSettleMember);
  }

  Future<void> _onLoadGroups(
    LoadGroupsEvent event,
    Emitter<GroupsState> emit,
  ) async {
    emit(GroupsLoading());
    try {
      final groups = await getGroupsUseCase();
      final debtSummary = await getDebtSummaryUseCase();
      final allMembers = await getConsolidatedMembersUseCase();
      final defaultGroupId = groups.isNotEmpty ? groups.first.id : '';
      final members = defaultGroupId.isNotEmpty
          ? await getGroupMembersUseCase(defaultGroupId)
          : <GroupMemberEntity>[];

      emit(GroupsLoaded(
        groups: groups,
        selectedGroupId: defaultGroupId,
        activeMembers: members,
        debtSummary: debtSummary,
        allMembers: allMembers,
      ));
    } catch (e) {
      emit(GroupsError('فشل تحميل المجموعات: $e'));
    }
  }

  Future<void> _onSelectGroup(
    SelectGroupEvent event,
    Emitter<GroupsState> emit,
  ) async {
    if (state is GroupsLoaded) {
      final current = state as GroupsLoaded;
      try {
        final members = await getGroupMembersUseCase(event.groupId);
        emit(current.copyWith(
          selectedGroupId: event.groupId,
          activeMembers: members,
        ));
      } catch (e) {
        emit(GroupsError('فشل تحميل أعضاء المجموعة: $e'));
      }
    }
  }

  Future<void> _onAddSharedExpense(
    AddSharedExpenseEvent event,
    Emitter<GroupsState> emit,
  ) async {
    try {
      await addGroupExpenseUseCase(event.expense);
      add(LoadGroupsEvent());
    } catch (e) {
      emit(GroupsError('فشل إضافة الفاتورة المشتركة: $e'));
    }
  }

  Future<void> _onAddGroupMember(
    AddGroupMemberEvent event,
    Emitter<GroupsState> emit,
  ) async {
    try {
      await addGroupMemberUseCase(event.member);
      final targetGroupId = event.member.groupId.isNotEmpty
          ? event.member.groupId
          : (state is GroupsLoaded ? (state as GroupsLoaded).selectedGroupId : '');
      final members = targetGroupId.isNotEmpty
          ? await getGroupMembersUseCase(targetGroupId)
          : <GroupMemberEntity>[];
      final debtSummary = await getDebtSummaryUseCase();
      final groups = await getGroupsUseCase();
      final allMembers = await getConsolidatedMembersUseCase();
      emit(GroupsLoaded(
        groups: groups,
        selectedGroupId: targetGroupId,
        activeMembers: members,
        debtSummary: debtSummary,
        allMembers: allMembers,
      ));
    } catch (e) {
      emit(GroupsError('فشل إضافة العضو: $e'));
    }
  }

  Future<void> _onAddExistingMemberToGroup(
    AddExistingMemberToGroupEvent event,
    Emitter<GroupsState> emit,
  ) async {
    try {
      final newMember = GroupMemberEntity(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        groupId: event.targetGroupId,
        name: event.memberName,
        avatarUrl: event.avatarUrl,
        balance: 0.0,
        note: event.note ?? 'تمت الإضافة من قائمة الأعضاء',
        lastActivity: 'الآن',
      );
      await addGroupMemberUseCase(newMember);

      final groups = await getGroupsUseCase();
      final currentSelectedId = state is GroupsLoaded
          ? (state as GroupsLoaded).selectedGroupId
          : (groups.isNotEmpty ? groups.first.id : '');
      final activeMembers = currentSelectedId.isNotEmpty
          ? await getGroupMembersUseCase(currentSelectedId)
          : <GroupMemberEntity>[];
      final debtSummary = await getDebtSummaryUseCase();
      final allMembers = await getConsolidatedMembersUseCase();

      emit(GroupsLoaded(
        groups: groups,
        selectedGroupId: currentSelectedId,
        activeMembers: activeMembers,
        debtSummary: debtSummary,
        allMembers: allMembers,
      ));
    } catch (e) {
      emit(GroupsError('فشل إضافة العضو إلى المجموعة: $e'));
    }
  }

  Future<void> _onAddGroup(
    AddGroupEvent event,
    Emitter<GroupsState> emit,
  ) async {
    try {
      await addGroupUseCase(event.group);
      final groups = await getGroupsUseCase();
      final members = await getGroupMembersUseCase(event.group.id);
      final debtSummary = await getDebtSummaryUseCase();
      final allMembers = await getConsolidatedMembersUseCase();
      emit(GroupsLoaded(
        groups: groups,
        selectedGroupId: event.group.id,
        activeMembers: members,
        debtSummary: debtSummary,
        allMembers: allMembers,
      ));
    } catch (e) {
      emit(GroupsError('فشل إنشاء المجموعة: $e'));
    }
  }

  Future<void> _onCreateGroupWithMembers(
    CreateGroupWithMembersEvent event,
    Emitter<GroupsState> emit,
  ) async {
    try {
      await addGroupUseCase(event.group);
      for (final member in event.members) {
        await addGroupMemberUseCase(member);
      }
      final groups = await getGroupsUseCase();
      final members = await getGroupMembersUseCase(event.group.id);
      final debtSummary = await getDebtSummaryUseCase();
      final allMembers = await getConsolidatedMembersUseCase();
      emit(GroupsLoaded(
        groups: groups,
        selectedGroupId: event.group.id,
        activeMembers: members,
        debtSummary: debtSummary,
        allMembers: allMembers,
      ));
    } catch (e) {
      emit(GroupsError('فشل إنشاء المجموعة وأعضائها: $e'));
    }
  }

  Future<void> _onSettleMember(
    SettleMemberEvent event,
    Emitter<GroupsState> emit,
  ) async {
    try {
      await settleBalanceUseCase(memberId: event.memberId, groupId: event.groupId);
      if (state is GroupsLoaded) {
        final current = state as GroupsLoaded;
        final members = await getGroupMembersUseCase(event.groupId);
        final debtSummary = await getDebtSummaryUseCase();
        final allMembers = await getConsolidatedMembersUseCase();
        emit(current.copyWith(
          activeMembers: members,
          debtSummary: debtSummary,
          allMembers: allMembers,
        ));
      }
    } catch (e) {
      emit(GroupsError('فشل تسوية الحساب: $e'));
    }
  }
}


