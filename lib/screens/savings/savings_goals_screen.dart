import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../models/savings_goal.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);
    final goals = db.savingsGoals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalSheet(context),
          ),
        ],
      ),
      body: goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings, size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No savings goals', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddGoalSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Goal'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => db.loadAll(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,
                itemBuilder: (ctx, i) => _GoalCard(goal: goals[i], db: db),
              ),
            ),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddGoalSheet(),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final DatabaseProvider db;
  const _GoalCard({required this.goal, required this.db});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.progress.clamp(0.0, 1.0);
    final color = Color(goal.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showGoalDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 60, height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60, height: 60,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: color,
                      ),
                    ),
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}', style: theme.textTheme.bodySmall),
                    if (goal.deadline != null)
                      Text('Due: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalDetail(BuildContext context) {
    final amtCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.name, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: goal.progress.clamp(0, 1), minHeight: 8, color: Color(goal.color)),
            const SizedBox(height: 8),
            Text('${CurrencyFormatter.format(goal.currentAmount)} of ${CurrencyFormatter.format(goal.targetAmount)} (${(goal.progress * 100).toStringAsFixed(0)}%)'),
            if (goal.deadline != null) Text('Deadline: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}'),
            const SizedBox(height: 16),
            if (!goal.isCompleted) ...[
              TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Add Amount (৳)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () {
                  final amt = double.tryParse(amtCtrl.text) ?? 0;
                  if (amt > 0) { db.addToSavingsGoal(goal.id!, amt); }
                  Navigator.pop(ctx);
                },
                child: const Text('Add to Goal'),
              )),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.income.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [const Icon(Icons.celebration, color: AppColors.income), const SizedBox(width: 8), Text('Goal completed! 🎉', style: TextStyle(color: AppColors.income))]),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet();

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  DateTime? _deadline;
  int? _accountId;
  int _priority = 0;
  int _selectedColor = 0xFF006B5E;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
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
            Text('New Savings Goal', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Goal Name', hintText: 'e.g., New Phone, Hajj, Car'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _targetCtrl, decoration: const InputDecoration(labelText: 'Target Amount (৳)'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _currentCtrl, decoration: const InputDecoration(labelText: 'Initial Deposit (optional)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _accountId,
              decoration: const InputDecoration(labelText: 'Linked Account'),
              items: db.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_deadline != null ? 'Deadline: ${DateFormat('dd/MM/yyyy').format(_deadline!)}' : 'Deadline (optional)'),
              onTap: () async { final p = await showDatePicker(context: context, initialDate: _deadline ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2035)); if (p != null) setState(() => _deadline = p); },
            ),
            const SizedBox(height: 12),
            Text('Color', style: theme.textTheme.bodyMedium),
            Wrap(spacing: 8, children: AppTheme.accentColors.map((c) => GestureDetector(
              onTap: () => setState(() => _selectedColor = c.value),
              child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: _selectedColor == c.value ? Border.all(color: theme.colorScheme.onSurface, width: 2) : null)),
            )).toList()),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                db.insertSavingsGoal(SavingsGoal(
                  name: _nameCtrl.text.trim(), targetAmount: double.parse(_targetCtrl.text),
                  currentAmount: double.tryParse(_currentCtrl.text) ?? 0, deadline: _deadline,
                  accountId: _accountId, color: _selectedColor, priority: _priority,
                ));
                Navigator.pop(context);
              },
              child: const Text('Create Goal'),
            )),
          ],
        ),
      ),
    );
  }
}
