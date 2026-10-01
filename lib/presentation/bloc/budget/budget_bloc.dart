import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/budget_summary.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../../domain/usecases/budget/budget_usecases.dart';

// EVENTS
abstract class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgetDashboardEvent extends BudgetEvent {}

class AddPersonalTransactionEvent extends BudgetEvent {
  final TransactionItem transaction;
  const AddPersonalTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class UpdatePersonalTransactionEvent extends BudgetEvent {
  final TransactionItem transaction;
  const UpdatePersonalTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class DeletePersonalTransactionEvent extends BudgetEvent {
  final String transactionId;
  const DeletePersonalTransactionEvent(this.transactionId);
  @override
  List<Object?> get props => [transactionId];
}

// STATES
abstract class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final BudgetSummary summary;
  final List<TransactionItem> recentTransactions;
  final List<TransactionItem> allTransactions;

  const BudgetLoaded({
    required this.summary,
    required this.recentTransactions,
    this.allTransactions = const [],
  });

  @override
  List<Object?> get props => [summary, recentTransactions, allTransactions];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
  @override
  List<Object?> get props => [message];
}

/// [BudgetBloc] orchestrates personal budget analytics, category charts, and transaction feeds.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudgetSummaryUseCase getBudgetSummaryUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final GetAllTransactionsUseCase getAllTransactionsUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  BudgetBloc({
    required this.getBudgetSummaryUseCase,
    required this.getTransactionsUseCase,
    required this.getAllTransactionsUseCase,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
  }) : super(BudgetInitial()) {
    on<LoadBudgetDashboardEvent>(_onLoadBudget);
    on<AddPersonalTransactionEvent>(_onAddTransaction);
    on<UpdatePersonalTransactionEvent>(_onUpdateTransaction);
    on<DeletePersonalTransactionEvent>(_onDeleteTransaction);
  }

  Future<void> _onLoadBudget(
    LoadBudgetDashboardEvent event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final summary = await getBudgetSummaryUseCase();
      final recentTransactions = await getTransactionsUseCase(limit: 10);
      final allTransactions = await getAllTransactionsUseCase();
      emit(BudgetLoaded(
        summary: summary,
        recentTransactions: recentTransactions,
        allTransactions: allTransactions,
      ));
    } catch (e) {
      emit(BudgetError('فشل تحميل بيانات الميزانية: $e'));
    }
  }

  Future<void> _onAddTransaction(
    AddPersonalTransactionEvent event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await addTransactionUseCase(event.transaction);
      add(LoadBudgetDashboardEvent());
    } catch (e) {
      emit(BudgetError('فشل حفظ العملية: $e'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdatePersonalTransactionEvent event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await updateTransactionUseCase(event.transaction);
      add(LoadBudgetDashboardEvent());
    } catch (e) {
      emit(BudgetError('فشل تعديل العملية: $e'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeletePersonalTransactionEvent event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await deleteTransactionUseCase(event.transactionId);
      add(LoadBudgetDashboardEvent());
    } catch (e) {
      emit(BudgetError('فشل حذف العملية: $e'));
    }
  }
}
