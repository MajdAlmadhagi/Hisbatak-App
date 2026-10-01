import 'package:flutter/material.dart';
import 'package:hisbatak_app/core/theme/app_theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../add_expense/add_expense_bottom_sheet.dart';
import '../groups/groups_screen.dart';
import '../home/home_budget_screen.dart';
import '../settings/settings_screen.dart';

/// [MainNavigationScreen] provides the persistent bottom navigation shell for Hisbatak.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _showAddExpenseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddExpenseBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeBudgetScreen(key: ValueKey('tab_home')),
          GroupsScreen(key: ValueKey('tab_groups')),
          SettingsScreen(key: ValueKey('tab_settings')),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onAddExpenseTap: _showAddExpenseModal,
      ),
    );
  }
}
