import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../models/budget.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);
    final monthBudgets = db.budgets.where((b) => b.month == _month && b.year == _year).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() { if (_month == 1) { _month = 12; _year--; } else { _month--; } })),
                  Text(DateFormat('MMMM yyyy').format(DateTime(_year, _month)), style: theme.textTheme.titleMedium),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() { if (_month == 12) { _month = 1; _year++; } else { _month++; } })),
                ],
              ),
            ),
          ),
          Expanded(
            child: monthBudgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No budgets for this month', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddBudgetSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Set Budget'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => db.loadAll(),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: monthBudgets.map((b) => _BudgetCard(
                        budget: b,
                        spent: db.getExpensesForCategory(b.categoryId, _month, _year),
                        categoryName: db.getCategory(b.categoryId)?.name ?? 'Unknown',
                        categoryColor: Color(db.getCategory(b.categoryId)?.color ?? 0xFF006B5E),
                        db: db,
                      )).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetSheet(BuildContext context) {
    final db = context.read<DatabaseProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddBudgetSheet(month: _month, year: _year),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final double spent;
  final String categoryName;
  final Color categoryColor;
  final DatabaseProvider db;
  const _BudgetCard({required this.budget, required this.spent, required this.categoryName, required this.categoryColor, required this.db});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = budget.amount > 0 ? spent / budget.amount : 0.0;
    final color = pct > 1 ? AppColors.expense : (pct > 0.8 ? AppColors.warning : AppColors.income);
    final remaining = budget.amount - spent;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 32, decoration: BoxDecoration(color: categoryColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Expanded(child: Text(categoryName, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
                Text('${(pct * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${CurrencyFormatter.format(spent)} spent', style: theme.textTheme.bodySmall?.copyWith(color: color)),
                Text('${CurrencyFormatter.format(budget.amount)} budget', style: theme.textTheme.bodySmall),
                Text('${CurrencyFormatter.format(remaining)} left', style: theme.textTheme.bodySmall?.copyWith(color: remaining >= 0 ? AppColors.income : AppColors.expense)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBudgetSheet extends StatefulWidget {
  final int month, year;
  const _AddBudgetSheet({required this.month, required this.year});

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  int? _categoryId;
  int _month = 0, _year = 0;

  @override
  void initState() {
    super.initState();
    _month = widget.month;
    _year = widget.year;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Budget', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: db.expenseCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Budget Amount (৳)'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('${DateFormat('MMMM').format(DateTime(_year, _month))} $_year', style: theme.textTheme.bodyMedium)),
              TextButton(onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime(_year, _month), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) setState(() { _month = picked.month; _year = picked.year; });
              }, child: const Text('Change')),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                db.insertBudget(Budget(categoryId: _categoryId!, month: _month, year: _year, amount: double.parse(_amountCtrl.text)));
                Navigator.pop(context);
              },
              child: const Text('Save Budget'),
            )),
          ],
        ),
      ),
    );
  }
}
