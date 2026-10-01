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

class SettleMemberEvent extends GroupsEvent {
  final String memberId;
  final String groupId;
  const SettleMemberEvent({required this.memberId, required this.groupId});
  @override
  List<Object?> get props => [memberId, groupId];
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

  const GroupsLoaded({
    required this.groups,
    required this.selectedGroupId,
    required this.activeMembers,
    required this.debtSummary,
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
  }) {
    return GroupsLoaded(
      groups: groups ?? this.groups,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      activeMembers: activeMembers ?? this.activeMembers,
      debtSummary: debtSummary ?? this.debtSummary,
    );
  }

  @override
  List<Object?> get props => [groups, selectedGroupId, activeMembers, debtSummary];
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
  final SettleBalanceUseCase settleBalanceUseCase;

  GroupsBloc({
    required this.getGroupsUseCase,
    required this.getGroupMembersUseCase,
    required this.getDebtSummaryUseCase,
    required this.addGroupExpenseUseCase,
    required this.settleBalanceUseCase,
  }) : super(GroupsInitial()) {
    on<LoadGroupsEvent>(_onLoadGroups);
    on<SelectGroupEvent>(_onSelectGroup);
    on<AddSharedExpenseEvent>(_onAddSharedExpense);
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
      final defaultGroupId = groups.isNotEmpty ? groups.first.id : '';
      final members = defaultGroupId.isNotEmpty
          ? await getGroupMembersUseCase(defaultGroupId)
          : <GroupMemberEntity>[];

      emit(GroupsLoaded(
        groups: groups,
        selectedGroupId: defaultGroupId,
        activeMembers: members,
        debtSummary: debtSummary,
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
        emit(current.copyWith(
          activeMembers: members,
          debtSummary: debtSummary,
        ));
      }
    } catch (e) {
      emit(GroupsError('فشل تسوية الحساب: $e'));
    }
  }
}
