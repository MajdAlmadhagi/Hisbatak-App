import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../widgets/transaction_details_dialog.dart';
import '../../widgets/hisbatak_loader.dart';
import '../../widgets/transaction_list_tile.dart';

/// [AllTransactionsScreen] displays the full transaction history with live search,
/// category filtering, type filtering (Income vs Expense), and financial summary totals.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Presentation and filtering of historical transactions.
/// - Open/Closed Principle (OCP): New filter criteria can be introduced cleanly.
class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTypeFilter = 'all'; // 'all', 'expense', 'income'
  String _selectedCategoryFilter = 'all'; // 'all' or category name

  final List<String> _categories = const [
    'الكل',
    'بقالة وتموين',
    'مطاعم ومقاهي',
    'فواتير ومسكن',
    'ترفيه وتسوق',
    'نقل ومواصلات',
    'راتب ودخل',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionItem> _filterTransactions(
      List<TransactionItem> transactions) {
    return transactions.where((tx) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = tx.title.toLowerCase().contains(query);
        final matchesCat = tx.category.toLowerCase().contains(query);
        final matchesPayment = tx.paymentMethod.toLowerCase().contains(query);
        final matchesAmount = tx.amount.toString().contains(query);
        if (!matchesTitle && !matchesCat && !matchesPayment && !matchesAmount) {
          return false;
        }
      }

      // 2. Type Filter (Expense / Income)
      if (_selectedTypeFilter == 'expense' &&
          tx.type != TransactionType.expense) {
        return false;
      }
      if (_selectedTypeFilter == 'income' &&
          tx.type != TransactionType.income) {
        return false;
      }

      // 3. Category Filter
      if (_selectedCategoryFilter != 'all' &&
          tx.category != _selectedCategoryFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appCardBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.appTextPrimary,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, state) {
            final count =
                (state is BudgetLoaded) ? state.allTransactions.length : 0;
            return Row(
              children: [
                Text(
                  AppStrings.allTransactionsTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.emerald.withValues(alpha: 0.2)
                        : AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.mintContainer : AppColors.emerald,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.appBorder, height: 1.0),
        ),
      ),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const Center(
              child: HisbatakLoader(),
            );
          }

          if (state is BudgetError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: AppColors.expense),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: TextStyle(color: context.appTextPrimary)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<BudgetBloc>()
                        .add(LoadBudgetDashboardEvent()),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald),
                    child: const Text('إعادة المحاولة',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final allTx = (state is BudgetLoaded)
              ? state.allTransactions
              : <TransactionItem>[];
          final filteredList = _filterTransactions(allTx);

          // Calculate summary statistics
          double totalExpenses = 0.0;
          double totalIncome = 0.0;
          for (final tx in allTx) {
            if (tx.type == TransactionType.expense) {
              totalExpenses += tx.amount;
            } else {
              totalIncome += tx.amount;
            }
          }
          final netBalance = totalIncome - totalExpenses;

          return RefreshIndicator(
            color: AppColors.emerald,
            onRefresh: () async {
              context.read<BudgetBloc>().add(LoadBudgetDashboardEvent());
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Top Financial Overview Summary Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    children: [
                      // Total Income
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.totalIncome,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: context.appTextSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${Formatters.formatCurrency(totalIncome)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.mintContainer
                                    : AppColors.income,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: context.appBorder),
                      // Total Expenses
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.totalExpenses,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.appTextSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '-${Formatters.formatCurrency(totalExpenses)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFF87171)
                                      : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 32, color: context.appBorder),
                      // Net Balance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppStrings.netBalance,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: context.appTextSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (netBalance >= 0 ? '+' : '') +
                                  Formatters.formatCurrency(netBalance),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: netBalance >= 0
                                    ? (isDark
                                        ? AppColors.mintContainer
                                        : AppColors.income)
                                    : (isDark
                                        ? const Color(0xFFF87171)
                                        : AppColors.expense),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    style:
                        TextStyle(color: context.appTextPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchTransactionPlaceholder,
                      hintStyle:
                          TextStyle(color: context.appTextMuted, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: context.appTextSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: context.appTextSecondary, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Type Filter Tabs (الكل / مصروفات / دخل)
                Row(
                  children: [
                    _buildFilterTab(
                      label: AppStrings.all,
                      isSelected: _selectedTypeFilter == 'all',
                      onTap: () => setState(() => _selectedTypeFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      label: AppStrings.expenses,
                      isSelected: _selectedTypeFilter == 'expense',
                      onTap: () =>
                          setState(() => _selectedTypeFilter = 'expense'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      label: AppStrings.income,
                      isSelected: _selectedTypeFilter == 'income',
                      onTap: () =>
                          setState(() => _selectedTypeFilter = 'income'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Horizontal Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected =
                          (_selectedCategoryFilter == 'all' && cat == 'الكل') ||
                              (_selectedCategoryFilter == cat);
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          selected: isSelected,
                          showCheckmark: false,
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.mintContainer
                                      : AppColors.emerald)
                                  : context.appTextSecondary,
                            ),
                          ),
                          backgroundColor: context.appCardBackground,
                          selectedColor: isDark
                              ? AppColors.emerald.withValues(alpha: 0.25)
                              : AppColors.mintFixed,
                          side: BorderSide(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.emerald
                                    : AppColors.emerald)
                                : context.appBorder,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryFilter =
                                  (cat == 'الكل') ? 'all' : cat;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Transactions List or Empty State
                if (filteredList.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: context.appTextMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.noTransactionsFound,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.appTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'جرّب تغيير كلمات البحث أو الفلاتر المحددة',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appTextMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredList.map((tx) {
                    return TransactionListTile(
                      item: tx,
                      onTap: () => TransactionDetailsDialog.show(context, tx),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return Expanded(
      child: Material(
        color: isSelected
            ? (isDark
                ? AppColors.emerald.withValues(alpha: 0.25)
                : AppColors.mintFixed)
            : context.appCardBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.emerald : context.appBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.mintContainer : AppColors.emerald)
                      : context.appTextSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
