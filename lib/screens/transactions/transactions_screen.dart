import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../models/transaction.dart';
import '../../models/recurring_rule.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  final String? initialType;
  const TransactionsScreen({super.key, this.initialType});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filterType = 'all';
  int? _filterAccountId;

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);
    var txList = db.transactions.where((t) {
      if (_filterType != 'all' && t.type != _filterType) return false;
      if (_filterAccountId != null && t.accountId != _filterAccountId && t.toAccountId != _filterAccountId) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addTransaction(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', selected: _filterType == 'all', onTap: () => setState(() => _filterType = 'all')),
                  _FilterChip(label: 'Income', selected: _filterType == 'income', onTap: () => setState(() => _filterType = 'income')),
                  _FilterChip(label: 'Expense', selected: _filterType == 'expense', onTap: () => setState(() => _filterType = 'expense')),
                  _FilterChip(label: 'Transfer', selected: _filterType == 'transfer', onTap: () => setState(() => _filterType = 'transfer')),
                ],
              ),
            ),
          ),
          Expanded(
            child: txList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No transactions', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _addTransaction(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Transaction'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => db.loadAll(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: txList.length,
                      itemBuilder: (ctx, i) => _TransactionCard(tx: txList[i], db: db),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _addTransaction(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const AddTransactionScreen(),
    ));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final dynamic tx;
  final DatabaseProvider db;
  const _TransactionCard({required this.tx, required this.db});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = db.getCategory(tx.categoryId);
    final acct = db.getAccount(tx.accountId);
    final isIncome = tx.type == 'income';
    final color = isIncome ? AppColors.income : (tx.type == 'transfer' ? AppColors.transfer : AppColors.expense);
    final icon = isIncome ? Icons.arrow_downward : (tx.type == 'transfer' ? Icons.swap_horiz : Icons.arrow_upward);

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => db.deleteTransaction(tx.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(cat?.name ?? tx.type, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          subtitle: Text('${acct?.name ?? ''} • ${DateFormat('dd MMM yyyy').format(tx.date)}', style: theme.textTheme.bodySmall),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
              if (tx.note != null && tx.note!.isNotEmpty)
                Text(tx.note!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
            ],
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddTransactionScreen(transaction: tx),
          )),
        ),
      ),
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
    default: return Icons.more_horiz;
  }
}

class AddTransactionScreen extends StatefulWidget {
  final dynamic transaction;
  final String? initialType;
  const AddTransactionScreen({super.key, this.transaction, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  String _type = 'expense';
  int? _categoryId;
  int? _accountId;
  int? _toAccountId;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  int _recurringInterval = 1;
  DateTime _recurringNextDate = DateTime.now();

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
    final t = widget.transaction;
    final initType = widget.initialType;
    _type = (t != null) ? t.type : (initType ?? 'expense');
    if (t != null) {
      _categoryId = t.categoryId;
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      _date = DateTime.tryParse(t.date.toString()) ?? DateTime.now();
      _isRecurring = t.isRecurring;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);
    final categories = _type == 'income' ? db.incomeCategories : db.expenseCategories;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: 'transfer', label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() {
                  _type = v.first;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount (৳)', prefixText: '৳ '),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (_type != 'transfer') ...[
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  isExpanded: true,
                  items: categories.map((c) {
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
                          Text(c.name, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<int>(
                value: _accountId,
                decoration: InputDecoration(labelText: _type == 'transfer' ? 'From Account' : 'Account'),
                isExpanded: true,
                items: db.accounts.map((a) {
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
                        Text(a.name, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _accountId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              if (_type == 'transfer') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _toAccountId,
                  decoration: const InputDecoration(labelText: 'To Account'),
                  isExpanded: true,
                  items: db.accounts.where((a) => a.id != _accountId).map((a) {
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
                          Text(a.name, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _toAccountId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd/MM/yyyy').format(_date)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Add a note...'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _recurringFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (v) => setState(() => _recurringFrequency = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Repeat every', suffixText: 'period(s)'),
                  keyboardType: TextInputType.number,
                  initialValue: _recurringInterval.toString(),
                  onChanged: (v) => _recurringInterval = int.tryParse(v) ?? 1,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text('Next: ${DateFormat('dd/MM/yyyy').format(_recurringNextDate)}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _recurringNextDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _recurringNextDate = picked);
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _save(db),
                  child: Text(_isEditing ? 'Update' : 'Add Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(DatabaseProvider db) async {
    if (!_formKey.currentState!.validate()) return;
    final tx = Transaction(
      id: widget.transaction?.id,
      amount: double.parse(_amountCtrl.text),
      type: _type,
      categoryId: _categoryId,
      accountId: _accountId!,
      toAccountId: _type == 'transfer' ? _toAccountId : null,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      isRecurring: _isRecurring,
    );
    if (_isEditing) {
      await db.updateTransaction(tx);
    } else {
      final txId = await db.insertTransaction(tx);
      if (_isRecurring) {
        await db.insertRecurringRule(RecurringRule(
          transactionId: txId,
          frequency: _recurringFrequency,
          intervalValue: _recurringInterval,
          nextDate: _recurringNextDate,
          isActive: true,
        ));
      }
    }
    if (mounted) Navigator.pop(context);
  }
}
