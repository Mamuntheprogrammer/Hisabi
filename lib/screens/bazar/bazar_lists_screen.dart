import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../models/bazar_list.dart';
import '../../models/bazar_item.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class BazarListsScreen extends StatefulWidget {
  const BazarListsScreen({super.key});

  @override
  State<BazarListsScreen> createState() => _BazarListsScreenState();
}

class _BazarListsScreenState extends State<BazarListsScreen> {
  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);
    final lists = db.bazarLists.where((l) => !l.isTemplate).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bazar List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewList(context),
          ),
        ],
      ),
      body: lists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart, size: 48, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  Text('No bazar lists', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Create your first shopping list',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _createNewList(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create List'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => db.loadAll(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lists.length,
                itemBuilder: (ctx, i) => _BazarListCard(list: lists[i], db: db),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewList(context),
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
    );
  }

  void _createNewList(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const _CreateBazarListScreen(),
    ));
  }
}

class _BazarListCard extends StatelessWidget {
  final BazarList list;
  final DatabaseProvider db;
  const _BazarListCard({required this.list, required this.db});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => _BazarListDetailScreen(list: list),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: list.isCompleted
                      ? AppColors.income.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  list.isCompleted ? Icons.check_circle : Icons.shopping_cart,
                  color: list.isCompleted ? AppColors.income : AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(list.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(list.date),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(list.totalEstimated),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (list.totalActual != null)
                    Text(
                      'Actual: ${CurrencyFormatter.format(list.totalActual!)}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.income),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${list.items.length} items',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateBazarListScreen extends StatefulWidget {
  const _CreateBazarListScreen();

  @override
  State<_CreateBazarListScreen> createState() => _CreateBazarListScreenState();
}

class _CreateBazarListScreenState extends State<_CreateBazarListScreen> {
  final _nameCtrl = TextEditingController();
  final _items = <_ItemEntry>[];

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final item in _items) {
      item.nameCtrl.dispose();
      item.qtyCtrl.dispose();
      item.priceCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Bazar List')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'List Name',
              hintText: 'e.g., Weekly Bazar, Eid Bazar',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Items',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_items.length} item${_items.length != 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('Tap "Add Item" to start',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
              ),
            ),
          ..._items.asMap().entries.map((e) => _ItemInputRow(
                index: e.key,
                item: e.value,
                onRemove: () {
                  e.value.nameCtrl.dispose();
                  e.value.qtyCtrl.dispose();
                  e.value.priceCtrl.dispose();
                  setState(() => _items.removeAt(e.key));
                },
              )),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _items.add(_ItemEntry())),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Total', style: theme.textTheme.titleMedium),
                    Text(
                      CurrencyFormatter.format(_items.fold(0.0,
                          (s, i) => s + ((double.tryParse(i.priceCtrl.text) ?? 0) * (double.tryParse(i.qtyCtrl.text) ?? 1)))),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _saveList(),
              icon: const Icon(Icons.save),
              label: const Text('Save & Start Shopping'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _saveList() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final db = context.read<DatabaseProvider>();
    final estimatedTotal = _items.fold(0.0,
        (s, i) => s + ((double.tryParse(i.priceCtrl.text) ?? 0) * (double.tryParse(i.qtyCtrl.text) ?? 1)));
    final listId = await db.insertBazarList(BazarList(
      name: name,
      date: DateTime.now(),
      totalEstimated: estimatedTotal,
    ));
    for (final item in _items) {
      final itemName = item.nameCtrl.text.trim();
      if (itemName.isEmpty) continue;
      await db.insertBazarItem(BazarItem(
        listId: listId,
        name: itemName,
        quantity: double.tryParse(item.qtyCtrl.text) ?? 1,
        unit: item.unit,
        priceEstimated: double.tryParse(item.priceCtrl.text) ?? 0,
      ));
    }
    if (mounted) Navigator.pop(context);
  }
}

class _ItemEntry {
  final nameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();
  String unit = 'pcs';
}

class _ItemInputRow extends StatelessWidget {
  final int index;
  final _ItemEntry item;
  final VoidCallback onRemove;
  const _ItemInputRow({
    required this.index,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle,
                      color: Colors.red, size: 20),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: '1',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: item.unit,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    items: Unit.units
                        .map((u) => DropdownMenuItem(
                            value: u['en'],
                            child: Text(u['en']!, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => item.unit = v ?? 'pcs',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: item.priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Est. Price (৳)',
                      hintText: '0',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BazarListDetailScreen extends StatefulWidget {
  final BazarList list;
  const _BazarListDetailScreen({required this.list});

  @override
  State<_BazarListDetailScreen> createState() => _BazarListDetailScreenState();
}

class _BazarListDetailScreenState extends State<_BazarListDetailScreen> {
  List<BazarItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final db = context.read<DatabaseProvider>();
    final items = await db.getBazarItems(widget.list.id!);
    if (mounted) setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseProvider>();
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.list.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final actualTotal = _items.fold(0.0, (s, i) => s + (i.priceActual ?? (i.priceEstimated * i.quantity)));
    final estTotal = _items.fold(0.0, (s, i) => s + (i.priceEstimated * i.quantity));
    final boughtItems = _items.where((i) => i.isBought).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _handleAction(v, db),
            itemBuilder: (ctx) {
              final items = <PopupMenuEntry<String>>[];
              if (!widget.list.isCompleted) {
                items.addAll([
                  const PopupMenuItem(
                    value: 'add',
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('Add Item'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Duplicate'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'template',
                    child: ListTile(
                      leading: Icon(Icons.bookmark),
                      title: Text('Save as Template'),
                      dense: true,
                    ),
                  ),
                ]);
              }
              if (!widget.list.isCompleted) {
                items.add(
                  const PopupMenuItem(
                    value: 'convert',
                    child: ListTile(
                      leading: Icon(Icons.receipt),
                      title: Text('Convert to Expense'),
                      dense: true,
                    ),
                  ),
                );
              }
              items.addAll([
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    dense: true,
                  ),
                ),
              ]);
              return items;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                    child: _Summary(
                        label: 'Items',
                        value: '${_items.length}',
                        icon: Icons.inventory)),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.3)),
                Expanded(
                    child: _Summary(
                        label: 'Bought',
                        value: '$boughtItems',
                        icon: Icons.check_circle)),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.3)),
                Expanded(
                    child: _Summary(
                        label: 'Est.',
                        value: CurrencyFormatter.format(estTotal),
                        icon: Icons.receipt)),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.3)),
                Expanded(
                    child: _Summary(
                        label: 'Actual',
                        value: CurrencyFormatter.format(actualTotal),
                        icon: Icons.payments)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Items',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('$boughtItems/${_items.length} bought',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadItems,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (ctx, i) => _ShoppingItemTile(
                  item: _items[i],
                  isListCompleted: widget.list.isCompleted,
                  onChanged: () => _loadItems(),
                  db: db,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, DatabaseProvider db) async {
    if (widget.list.isCompleted && (action == 'add' || action == 'duplicate' || action == 'template')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot edit a completed list')),
        );
      }
      return;
    }
    switch (action) {
      case 'add':
        _showAddItemDialog(db);
        break;
      case 'duplicate':
        final newId = await db.insertBazarList(BazarList(
          name: '${widget.list.name} (copy)',
          date: DateTime.now(),
        ));
        for (final item in _items) {
          await db.insertBazarItem(BazarItem(
            listId: newId,
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            priceEstimated: item.priceEstimated,
          ));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('List duplicated')),
          );
        }
        break;
      case 'template':
        final templateId = await db.insertBazarList(BazarList(
          name: '${widget.list.name} (template)',
          date: DateTime.now(),
          isTemplate: true,
        ));
        for (final item in _items) {
          await db.insertBazarItem(BazarItem(
            listId: templateId,
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            priceEstimated: item.priceEstimated,
          ));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved as template')),
          );
        }
        break;
      case 'convert':
        _convertToExpense(db, Theme.of(context));
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete List'),
            content: Text('Delete "${widget.list.name}" and all items?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await db.deleteBazarList(widget.list.id!);
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }

  void _showAddItemDialog(DatabaseProvider db) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    String unit = 'pcs';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: '1',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: unit,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    items: Unit.units
                        .map((u) => DropdownMenuItem(
                            value: u['en'],
                            child: Text(u['en']!, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => unit = v ?? 'pcs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                  labelText: 'Estimated Price (৳)',
                  hintText: '0',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await db.insertBazarItem(BazarItem(
                listId: widget.list.id!,
                name: nameCtrl.text.trim(),
                quantity: double.tryParse(qtyCtrl.text) ?? 1,
                unit: unit,
                priceEstimated: double.tryParse(priceCtrl.text) ?? 0,
              ));
              Navigator.pop(ctx);
              await _loadItems();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _convertToExpense(DatabaseProvider db, ThemeData theme) {
    final total = _items.fold(0.0,
        (s, i) => s + (i.priceActual ?? (i.priceEstimated * i.quantity)));

    Category? selectedCategory = widget.list.categoryId != null
        ? db.getCategory(widget.list.categoryId)
        : db.expenseCategories.isNotEmpty
            ? db.expenseCategories.first
            : null;
    Account? selectedAccount = widget.list.accountId != null
        ? db.getAccount(widget.list.accountId)
        : db.accounts.isNotEmpty
            ? db.accounts.first
            : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.receipt, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Convert to Expense'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('Total: ',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      CurrencyFormatter.format(total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: selectedCategory?.id,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: db.expenseCategories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (v) {
                  setDialogState(() {
                    selectedCategory = db.categories.firstWhere((c) => c.id == v);
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedAccount?.id,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: db.accounts.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name),
                )).toList(),
                onChanged: (v) {
                  setDialogState(() {
                    selectedAccount = db.accounts.firstWhere((a) => a.id == v);
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                'This will mark the list as completed and create an expense transaction.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () async {
                if (selectedCategory == null || selectedAccount == null) return;
                await db.insertTransaction(Transaction(
                  amount: total,
                  type: 'expense',
                  categoryId: selectedCategory!.id,
                  accountId: selectedAccount!.id!,
                  date: DateTime.now(),
                  note: 'Bazar: ${widget.list.name}',
                ));
                await db.updateBazarList(widget.list.copyWith(
                  totalActual: total,
                  isCompleted: true,
                  categoryId: selectedCategory!.id,
                  accountId: selectedAccount!.id,
                ));
                Navigator.pop(ctx);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Convert'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Summary({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _ShoppingItemTile extends StatefulWidget {
  final BazarItem item;
  final bool isListCompleted;
  final VoidCallback onChanged;
  final DatabaseProvider db;
  const _ShoppingItemTile({
    required this.item,
    required this.isListCompleted,
    required this.onChanged,
    required this.db,
  });

  @override
  State<_ShoppingItemTile> createState() => _ShoppingItemTileState();
}

class _ShoppingItemTileState extends State<_ShoppingItemTile> {
  late TextEditingController _actualPriceCtrl;

  @override
  void initState() {
    super.initState();
    _actualPriceCtrl = TextEditingController(
        text: widget.item.priceActual?.toStringAsFixed(0) ?? '');
  }

  @override
  void didUpdateWidget(_ShoppingItemTile old) {
    super.didUpdateWidget(old);
    if (old.item.priceActual != widget.item.priceActual) {
      _actualPriceCtrl.text =
          widget.item.priceActual?.toStringAsFixed(0) ?? '';
    }
  }

  @override
  void dispose() {
    _actualPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final estPrice = item.priceEstimated * item.quantity;
    final actualPrice = item.priceActual != null
        ? item.priceActual! * item.quantity
        : estPrice;
    final diff = actualPrice - estPrice;
    final hasActualPrice = item.priceActual != null;

    return Dismissible(
      key: ValueKey(item.id),
      direction: widget.isListCompleted ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: widget.isListCompleted ? null : (_) async {
        await widget.db.deleteBazarItem(item.id!);
        widget.onChanged();
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.isListCompleted ? null : () => _showEditDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: item.isBought,
                  activeColor: AppColors.income,
                  onChanged: widget.isListCompleted ? null : (v) async {
                    await widget.db
                        .updateBazarItem(item.copyWith(isBought: v ?? false));
                    widget.onChanged();
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: item.isBought
                              ? FontWeight.normal
                              : FontWeight.w500,
                          decoration: item.isBought
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isBought
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${item.quantity} ${item.unit} × ${CurrencyFormatter.format(item.priceEstimated)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (hasActualPrice && diff != 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      diff < 0 ? Icons.trending_down : Icons.trending_up,
                      size: 16,
                      color: diff < 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _actualPriceCtrl,
                    readOnly: widget.isListCompleted,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Actual',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: widget.isListCompleted ? null : (v) async {
                      final p = double.tryParse(v);
                      if (p != null) {
                        await widget.db
                            .updateBazarItem(item.copyWith(priceActual: p));
                        widget.onChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl =
        TextEditingController(text: widget.item.name);
    final qtyCtrl =
        TextEditingController(text: widget.item.quantity.toString());
    final priceEstCtrl =
        TextEditingController(text: widget.item.priceEstimated.toStringAsFixed(0));
    String unit = widget.item.unit;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Qty', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: unit,
                    decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        isDense: true),
                    items: Unit.units
                        .map((u) => DropdownMenuItem(
                            value: u['en'], child: Text(u['en']!)))
                        .toList(),
                    onChanged: (v) => unit = v ?? 'pcs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceEstCtrl,
              decoration: const InputDecoration(
                  labelText: 'Est. Price (৳)',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await widget.db.updateBazarItem(widget.item.copyWith(
                name: nameCtrl.text.trim(),
                quantity: double.tryParse(qtyCtrl.text) ??
                    widget.item.quantity,
                unit: unit,
                priceEstimated: double.tryParse(priceEstCtrl.text) ??
                    widget.item.priceEstimated,
              ));
              Navigator.pop(ctx);
              widget.onChanged();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
