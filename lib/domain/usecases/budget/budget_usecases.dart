import '../../entities/budget_summary.dart';
import '../../entities/transaction_item.dart';
import '../../repositories/i_budget_repository.dart';

/// [GetBudgetSummaryUseCase] retrieves budget totals, spending, and category distribution.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetBudgetSummaryUseCase {
  final IBudgetRepository repository;

  GetBudgetSummaryUseCase(this.repository);

  Future<BudgetSummary> call() async {
    return await repository.getBudgetSummary();
  }
}

/// [GetTransactionsUseCase] retrieves recent transaction history.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetTransactionsUseCase {
  final IBudgetRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<List<TransactionItem>> call({int limit = 10}) async {
    return await repository.getRecentTransactions(limit: limit);
  }
}

/// [GetAllTransactionsUseCase] retrieves all transaction records.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetAllTransactionsUseCase {
  final IBudgetRepository repository;

  GetAllTransactionsUseCase(this.repository);

  Future<List<TransactionItem>> call() async {
    return await repository.getAllTransactions();
  }
}

/// [AddTransactionUseCase] inserts a new personal transaction and updates budget balance.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AddTransactionUseCase {
  final IBudgetRepository repository;

  AddTransactionUseCase(this.repository);

  Future<void> call(TransactionItem transaction) async {
    return await repository.addTransaction(transaction);
  }
}

/// [UpdateTransactionUseCase] updates an existing transaction and recalculates budget.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class UpdateTransactionUseCase {
  final IBudgetRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<void> call(TransactionItem transaction) async {
    return await repository.updateTransaction(transaction);
  }
}

/// [DeleteTransactionUseCase] deletes a transaction and recalculates budget.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class DeleteTransactionUseCase {
  final IBudgetRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<void> call(String transactionId) async {
    return await repository.deleteTransaction(transactionId);
  }
}
