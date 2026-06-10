import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../models/debt.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/export_pdf.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Debt',
            onPressed: () => _showAddDebtSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Debt PDF',
            onPressed: () => exportDebtPdf(context, db.debts),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'I Owe (${db.debtsOwe.length})'),
            Tab(text: "I'm Owed (${db.debtsOwed.length})"),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 16, color: theme.colorScheme.error),
                      const SizedBox(width: 4),
                      Text('I Owe:', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.format(db.debtsOwe.fold(0.0, (s, d) => s + d.remaining)),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text("I'm Owed:", style: theme.textTheme.bodySmall),
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.format(db.debtsOwed.fold(0.0, (s, d) => s + d.remaining)),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DebtList(type: 'owe', theme: theme, db: db),
                _DebtList(type: 'owed', theme: theme, db: db),
              ],
            ),
          ),
        ],
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
    DatabaseProvider? dbProvider;
    Category? selectedCategory;
    Account? selectedAccount;

    showDialog(
      context: context,
      builder: (ctx) {
        dbProvider = ctx.read<DatabaseProvider>();
        final defaultCatName = debt.type == 'owe' ? 'Debt Owe' : 'Debt Owed';
        selectedCategory ??= dbProvider!.expenseCategories.firstWhere(
          (c) => c.name == defaultCatName,
          orElse: () => dbProvider!.expenseCategories.first,
        );
        selectedAccount ??= dbProvider!.accounts.isNotEmpty ? dbProvider!.accounts.first : null;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Add Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedCategory?.id,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: dbProvider!.expenseCategories.map((c) {
                    final catColor = Color(c.color);
                    return DropdownMenuItem<int>(
                      value: c.id,
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_iconFromString(c.icon), size: 16, color: catColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedCategory = dbProvider!.categories.firstWhere((c) => c.id == v);
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedAccount?.id,
                  decoration: const InputDecoration(
                    labelText: 'From Account',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: dbProvider!.accounts.map((a) {
                    final accColor = Color(a.color);
                    return DropdownMenuItem<int>(
                      value: a.id,
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: accColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_iconFromString(a.icon), size: 16, color: accColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(a.name, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedAccount = dbProvider!.accounts.firstWhere((a) => a.id == v);
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(onPressed: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                if (amt > 0 && selectedCategory != null && selectedAccount != null) {
                  await dbProvider!.insertTransaction(Transaction(
                    amount: amt,
                    type: 'expense',
                    categoryId: selectedCategory!.id,
                    accountId: selectedAccount!.id!,
                    date: DateTime.now(),
                    note: 'Debt payment: ${debt.personName}',
                  ));
                  await dbProvider!.updateDebt(Debt(
                    id: debt.id, personName: debt.personName, phone: debt.phone,
                    amount: debt.amount, amountPaid: debt.amountPaid + amt,
                    type: debt.type, date: debt.date, dueDate: debt.dueDate, note: debt.note,
                    status: (debt.amountPaid + amt) >= debt.amount ? 'cleared' : 'partial',
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }, child: const Text('Pay')),
            ],
          ),
        );
      },
    );
  }
}

IconData _iconFromString(String icon) {
  switch (icon) {
    case 'account_balance': return Icons.account_balance;
    case 'restaurant': return Icons.restaurant;
    case 'home': return Icons.home;
    case 'medical_services': return Icons.medical_services;
    case 'school': return Icons.school;
    case 'checkroom': return Icons.checkroom;
    case 'directions_bus': return Icons.directions_bus;
    case 'bolt': return Icons.bolt;
    case 'smartphone': return Icons.smartphone;
    case 'volunteer_activism': return Icons.volunteer_activism;
    case 'celebration': return Icons.celebration;
    case 'local_dining': return Icons.local_dining;
    case 'child_care': return Icons.child_care;
    case 'spa': return Icons.spa;
    case 'build': return Icons.build;
    case 'movie': return Icons.movie;
    case 'shopping_cart': return Icons.shopping_cart;
    case 'flight': return Icons.flight;
    case 'security': return Icons.security;
    case 'payments': return Icons.payments;
    case 'mosque': return Icons.mosque;
    case 'work': return Icons.work;
    case 'business': return Icons.business;
    case 'laptop': return Icons.laptop;
    case 'trending_up': return Icons.trending_up;
    case 'card_giftcard': return Icons.card_giftcard;
    case 'add_circle': return Icons.add_circle;
    case 'directions_car': return Icons.directions_car;
    case 'store': return Icons.store;
    case 'monetization_on': return Icons.monetization_on;
    case 'inventory': return Icons.inventory;
    case 'agriculture': return Icons.agriculture;
    case 'savings': return Icons.savings;
    case 'piggy_bank': return Icons.savings;
    case 'arrow_upward': return Icons.arrow_upward;
    case 'arrow_downward': return Icons.arrow_downward;
    default: return Icons.more_horiz;
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
      child: SingleChildScrollView(
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
      ),
    );
  }
}
