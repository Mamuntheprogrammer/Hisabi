import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../models/debt.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'I Owe (${db.debtsOwe.length})'),
            Tab(text: "I'm Owed (${db.debtsOwed.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DebtList(type: 'owe', theme: theme, db: db),
          _DebtList(type: 'owed', theme: theme, db: db),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDebtSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddDebtSheet(),
    );
  }
}

class _DebtList extends StatelessWidget {
  final String type;
  final ThemeData theme;
  final DatabaseProvider db;
  const _DebtList({required this.type, required this.theme, required this.db});

  @override
  Widget build(BuildContext context) {
    final list = type == 'owe' ? db.debtsOwe : db.debtsOwed;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type == 'owe' ? Icons.arrow_upward : Icons.arrow_downward, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(type == 'owe' ? 'No debts you owe' : "No one owes you", style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => db.loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) => _DebtCard(debt: list[i], db: db),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final DatabaseProvider db;
  const _DebtCard({required this.debt, required this.db});

  Color _statusColor(String status) {
    switch (status) {
      case 'cleared': return AppColors.income;
      case 'partial': return AppColors.warning;
      default: return AppColors.expense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwe = debt.type == 'owe';
    final color = isOwe ? AppColors.expense : AppColors.income;

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) => db.deleteDebt(debt.id!),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDebtDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(isOwe ? Icons.arrow_upward : Icons.arrow_downward, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.personName, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                      if (debt.note != null) Text(debt.note!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (debt.dueDate != null) Text('Due: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(CurrencyFormatter.format(debt.amount), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (debt.amountPaid > 0) Text('Paid: ${CurrencyFormatter.format(debt.amountPaid)}', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.income)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _statusColor(debt.status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(debt.status.toUpperCase(), style: TextStyle(fontSize: 10, color: _statusColor(debt.status), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDebtDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(debt.personName, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Amount: ${CurrencyFormatter.format(debt.amount)}'),
            if (debt.amountPaid > 0) Text('Paid: ${CurrencyFormatter.format(debt.amountPaid)}'),
            Text('Remaining: ${CurrencyFormatter.format(debt.remaining)}'),
            if (debt.dueDate != null) Text('Due: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}'),
            if (debt.note != null) Text('Note: ${debt.note}'),
            const SizedBox(height: 16),
            if (!debt.isCleared) ...[
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showPaymentDialog(context);
                },
                child: const Text('Add Payment'),
              )),
              const SizedBox(height: 8),
            ],
            SizedBox(width: double.infinity, child: TextButton(
              onPressed: () { Navigator.pop(ctx); db.deleteDebt(debt.id!); },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            )),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payment'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final amt = double.tryParse(ctrl.text) ?? 0;
            if (amt > 0) {
              db.updateDebt(Debt(
                id: debt.id, personName: debt.personName, phone: debt.phone,
                amount: debt.amount, amountPaid: debt.amountPaid + amt,
                type: debt.type, date: debt.date, dueDate: debt.dueDate, note: debt.note,
                status: (debt.amountPaid + amt) >= debt.amount ? 'cleared' : 'partial',
              ));
            }
            Navigator.pop(ctx);
          }, child: const Text('Pay')),
        ],
      ),
    );
  }
}

class _AddDebtSheet extends StatefulWidget {
  const _AddDebtSheet();

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'owe';
  DateTime _date = DateTime.now();
  DateTime? _dueDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Debt', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'owe', label: Text('I Owe'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'owed', label: Text("I'm Owed"), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Person Name'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (optional)'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextFormField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount (৳)'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('Date: ${DateFormat('dd/MM/yyyy').format(_date)}'),
              onTap: () async { final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (p != null) setState(() => _date = p); },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_dueDate != null ? 'Due: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}' : 'Due Date (optional)'),
              onTap: () async { final p = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (p != null) setState(() => _dueDate = p); },
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)'), maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                context.read<DatabaseProvider>().insertDebt(Debt(
                  personName: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                  amount: double.parse(_amountCtrl.text), type: _type, date: _date, dueDate: _dueDate,
                  note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                ));
                Navigator.pop(context);
              },
              child: const Text('Add Debt'),
            )),
          ],
        ),
      ),
    );
  }
}
