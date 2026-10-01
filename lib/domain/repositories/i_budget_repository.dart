import '../entities/budget_summary.dart';
import '../entities/transaction_item.dart';

/// [IBudgetRepository] defines personal budget and transaction storage operations.
///
/// SOLID Principles:
/// - Interface Segregation Principle (ISP): Focused solely on personal budgeting and transactions.
/// - Dependency Inversion Principle (DIP): Inversion of dependency away from concrete SQLite classes.
abstract class IBudgetRepository {
  Future<BudgetSummary> getBudgetSummary();
  Future<List<TransactionItem>> getRecentTransactions({int limit = 10});
  Future<List<TransactionItem>> getAllTransactions();
  Future<void> addTransaction(TransactionItem transaction);
  Future<void> updateTransaction(TransactionItem transaction);
  Future<void> deleteTransaction(String transactionId);
}
