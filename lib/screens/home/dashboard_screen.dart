import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../accounts/accounts_screen.dart';
import '../bazar/bazar_lists_screen.dart';
import '../debts/debts_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    CurrencyFormatter.symbol = settings.currencySymbol;

    Widget body;
    switch (_currentIndex) {
      case 1:
        body = const AccountsScreen();
        break;
      case 2:
        body = const ReportsScreen();
        break;
      case 3:
        body = const DebtsScreen();
        break;
      case 4:
        body = const BazarListsScreen();
        break;
      case 5:
        body = const SettingsScreen();
        break;
      default:
        body = _DashboardContent(db: db, settings: settings, theme: theme);
    }

    return Scaffold(
      extendBody: _currentIndex == 0,
      appBar: _currentIndex == 0
          ? AppBar(
              title: _ColorfulAppName(),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(context.read<ThemeProvider>().isDarkMode ? Icons.light_mode : Icons.dark_mode, size: 20),
                    onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                  ),
                ),

              ],
            )
          : null,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        elevation: 0,
        shadowColor: Colors.transparent,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance), label: 'Accounts'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.money_off_outlined), selectedIcon: Icon(Icons.money_off), label: 'Debt'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Bazar'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddTransactionSheet(context),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _DashboardContent({
    required DatabaseProvider db,
    required SettingsProvider settings,
    required ThemeData theme,
  }) {
    final now = DateTime.now();
    final income = db.getIncomeForMonth(now.month, now.year);
    final expense = db.getExpensesForMonth(now.month, now.year);
    final savings = income - expense;

    if (db.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => db.loadAll(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          _NetWorthCard(balance: db.totalBalance, settings: settings),
          const SizedBox(height: 12),
          _IncomeExpenseRow(income: income, expense: expense, savings: savings, settings: settings),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 10),
          _QuickActions(onBazarTap: () => setState(() => _currentIndex = 4)),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Recent Transactions'),
          const SizedBox(height: 10),
          ...db.getRecentTransactions(limit: 5).map((t) => _TransactionTile(t: t, db: db, settings: settings)),
          if (db.getRecentTransactions(limit: 5).isEmpty)
            _EmptyCard(
              icon: Icons.receipt_long_outlined,
              message: 'No transactions yet',
              actionLabel: 'Add your first transaction',
              onAction: () => _showAddTransactionSheet(context),
            ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Top Spending Categories'),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: db.getTopExpenseCategories(now.month, now.year, limit: 5).map((e) => _CategoryBar(
                  category: e.key,
                  amount: e.value,
                  total: expense,
                  settings: settings,
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Upcoming Recurring'),
          const SizedBox(height: 10),
          ...db.getUpcomingRecurring(limit: 5).map((e) => _RecurringTile(
            rule: e.key,
            transaction: e.value,
            db: db,
            settings: settings,
          )),
          if (db.getUpcomingRecurring(limit: 5).isEmpty)
            _EmptyCard(
              icon: Icons.repeat_outlined,
              message: 'No upcoming recurring',
              actionLabel: 'Mark a transaction as recurring',
              onAction: () {},
            ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Transaction', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _ActionCard(icon: Icons.arrow_downward, label: 'Income', color: AppColors.income, onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(ctx, '/add-transaction', arguments: {'type': 'income'});
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionCard(icon: Icons.arrow_upward, label: 'Expense', color: AppColors.expense, onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(ctx, '/add-transaction', arguments: {'type': 'expense'});
                  })),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _ActionCard(icon: Icons.swap_horiz, label: 'Transfer', color: AppColors.transfer, onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(ctx, '/add-transaction', arguments: {'type': 'transfer'});
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionCard(icon: Icons.shopping_cart, label: 'Bazar', color: AppTheme.primaryColor, onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 4);
                  })),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorfulAppName extends StatelessWidget {
  const _ColorfulAppName();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return Text(
      'Hisabi',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  final double balance;
  final SettingsProvider settings;
  const _NetWorthCard({required this.balance, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(blue: 0.7, alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.9), size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(isPositive ? 'On Track' : 'Attention', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Net Worth', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            settings.formatAmount(balance),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  final double income, expense, savings;
  final SettingsProvider settings;
  const _IncomeExpenseRow({required this.income, required this.expense, required this.savings, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendingRatio = income > 0 ? (expense / income).clamp(0.0, 1.0) : 0.0;
    final savingsRatio = income > 0 ? (savings / income).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _StatBadge(label: 'Income', amount: income, color: AppColors.income, settings: settings)),
                Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                Expanded(child: _StatBadge(label: 'Expense', amount: expense, color: AppColors.expense, settings: settings)),
                Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                Expanded(child: _StatBadge(label: 'Savings', amount: savings, color: savings >= 0 ? AppColors.income : AppColors.expense, settings: settings)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Flexible(
                    flex: (spendingRatio * 100).round().clamp(1, 100),
                    child: Container(height: 8, color: AppColors.expense.withValues(alpha: 0.8)),
                  ),
                  Flexible(
                    flex: (savingsRatio * 100).round().clamp(1, 100),
                    child: Container(height: 8, color: AppColors.income.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final SettingsProvider settings;
  const _StatBadge({required this.label, required this.amount, required this.color, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(settings.formatAmount(amount), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onBazarTap;
  const _QuickActions({required this.onBazarTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionCard(icon: Icons.arrow_downward, label: 'Income', color: AppColors.income, onTap: () => _add(context, 'income'))),
        const SizedBox(width: 10),
        Expanded(child: _ActionCard(icon: Icons.arrow_upward, label: 'Expense', color: AppColors.expense, onTap: () => _add(context, 'expense'))),
        const SizedBox(width: 10),
        Expanded(child: _ActionCard(icon: Icons.swap_horiz, label: 'Transfer', color: AppColors.transfer, onTap: () => _add(context, 'transfer'))),
        const SizedBox(width: 10),
        Expanded(child: _ActionCard(icon: Icons.shopping_cart, label: 'Bazar', color: AppTheme.primaryColor, onTap: onBazarTap)),
      ],
    );
  }

  void _add(BuildContext ctx, String type) {
    Navigator.pushNamed(ctx, '/add-transaction', arguments: {'type': type});
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface, letterSpacing: 0.3)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic t;
  final DatabaseProvider db;
  final SettingsProvider settings;
  const _TransactionTile({required this.t, required this.db, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = db.getCategory(t.categoryId);
    final acct = db.getAccount(t.accountId);
    final isIncome = t.type == 'income';
    final color = isIncome ? AppColors.income : (t.type == 'transfer' ? AppColors.transfer : AppColors.expense);
    final icon = isIncome ? Icons.arrow_downward : (t.type == 'transfer' ? Icons.swap_horiz : Icons.arrow_upward);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddTransactionScreen(transaction: t),
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat?.name ?? t.type, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${acct?.name ?? ''} • ${DateFormat('dd MMM').format(t.date)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${settings.formatAmount(t.amount)}',
                style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final dynamic category;
  final double amount;
  final double total;
  final SettingsProvider settings;
  const _CategoryBar({required this.category, required this.amount, required this.total, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total > 0 ? amount / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.name, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(settings.formatAmount(amount), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                fraction > 0.8 ? AppColors.expense : (fraction > 0.5 ? Colors.orange : AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final dynamic rule;
  final dynamic transaction;
  final DatabaseProvider db;
  final SettingsProvider settings;
  const _RecurringTile({required this.rule, required this.transaction, required this.db, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = db.getCategory(transaction.categoryId);
    final acct = db.getAccount(transaction.accountId);
    final isIncome = transaction.type == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat?.name ?? transaction.type, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${rule.frequency} • Next: ${DateFormat('dd MMM').format(rule.nextDate)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${settings.formatAmount(transaction.amount)}',
              style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  const _EmptyCard({required this.icon, required this.message, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel, style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
