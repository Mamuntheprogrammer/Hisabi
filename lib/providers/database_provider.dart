import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/savings_goal.dart';
import '../models/income_source.dart';
import '../models/recurring_rule.dart';
import '../models/bazar_list.dart';
import '../models/bazar_item.dart';

class DatabaseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Debt> _debts = [];
  List<SavingsGoal> _savingsGoals = [];
  List<IncomeSource> _incomeSources = [];
  List<BazarList> _bazarLists = [];
  List<RecurringRule> _recurringRules = [];

  bool _isLoading = false;

  List<Account> get accounts => _accounts.where((a) => a.isActive).toList();
  List<Account> get allAccounts => _accounts;
  List<Category> get categories => _categories;
  List<Category> get expenseCategories => _categories.where((c) => c.type == 'expense').toList();
  List<Category> get incomeCategories => _categories.where((c) => c.type == 'income').toList();
  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<Debt> get debts => _debts;
  List<Debt> get debtsOwe => _debts.where((d) => d.type == 'owe').toList();
  List<Debt> get debtsOwed => _debts.where((d) => d.type == 'owed').toList();
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<IncomeSource> get incomeSources => _incomeSources;
  List<BazarList> get bazarLists => _bazarLists;
  List<RecurringRule> get recurringRules => _recurringRules;
  bool get isLoading => _isLoading;

  double get totalBalance => _accounts.fold(0.0, (sum, a) => sum + a.balance);
  double get totalIncome => _transactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
  double get totalExpense => _transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);

  Account? getAccount(int? id) {
    if (id == null) return null;
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Category? getCategory(int? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      loadAccounts(),
      loadCategories(),
      loadTransactions(),
      loadBudgets(),
      loadDebts(),
      loadSavingsGoals(),
      loadIncomeSources(),
      loadBazarLists(),
      loadRecurringRules(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAccounts() async {
    final db = await _db.database;
    final maps = await db.query('accounts', orderBy: 'createdAt ASC');
    _accounts = maps.map((m) => Account.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'id ASC');
    _categories = maps.map((m) => Category.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    final db = await _db.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    _transactions = maps.map((m) => Transaction.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadBudgets() async {
    final db = await _db.database;
    final maps = await db.query('budgets');
    _budgets = maps.map((m) => Budget.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadDebts() async {
    final db = await _db.database;
    final maps = await db.query('debts', orderBy: 'date DESC');
    _debts = maps.map((m) => Debt.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadSavingsGoals() async {
    final db = await _db.database;
    final maps = await db.query('savings_goals', orderBy: 'createdAt DESC');
    _savingsGoals = maps.map((m) => SavingsGoal.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadIncomeSources() async {
    final db = await _db.database;
    final maps = await db.query('income_sources', orderBy: 'id ASC');
    _incomeSources = maps.map((m) => IncomeSource.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadBazarLists() async {
    final db = await _db.database;
    final maps = await db.query('bazar_lists', orderBy: 'date DESC');
    _bazarLists = maps.map((m) => BazarList.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadRecurringRules() async {
    final db = await _db.database;
    final maps = await db.query('recurring_rules', orderBy: 'nextDate ASC');
    _recurringRules = maps.map((m) => RecurringRule.fromMap(m)).toList();
    notifyListeners();
  }

  Future<int> insertAccount(Account account) async {
    final db = await _db.database;
    final id = await db.insert('accounts', account.toMap()..remove('id'));
    await loadAccounts();
    return id;
  }

  Future<void> updateAccount(Account account) async {
    final db = await _db.database;
    await db.update('accounts', account.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [account.id]);
    await loadAccounts();
  }

  Future<void> deleteAccount(int id) async {
    final db = await _db.database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
    await loadAccounts();
  }

  Future<int> insertTransaction(Transaction t) async {
    final db = await _db.database;
    final id = await db.insert('transactions', t.toMap()..remove('id'));
    await _recalcBalance(t.accountId);
    if (t.toAccountId != null) await _recalcBalance(t.toAccountId!);
    await loadTransactions();
    return id;
  }

  Future<void> updateTransaction(Transaction t) async {
    final db = await _db.database;
    final old = _transactions.firstWhere((x) => x.id == t.id);
    await db.update('transactions', t.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [t.id]);
    await _recalcBalance(old.accountId);
    if (old.toAccountId != null) await _recalcBalance(old.toAccountId!);
    await _recalcBalance(t.accountId);
    if (t.toAccountId != null) await _recalcBalance(t.toAccountId!);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _db.database;
    final t = _transactions.firstWhere((x) => x.id == id);
    await db.delete('recurring_rules', where: 'transactionId = ?', whereArgs: [id]);
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await _recalcBalance(t.accountId);
    if (t.toAccountId != null) await _recalcBalance(t.toAccountId!);
    await Future.wait([loadTransactions(), loadRecurringRules()]);
  }

  Future<void> _recalcBalance(int accountId) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) +
        COALESCE(SUM(CASE WHEN type = 'transfer' AND toAccountId = ? THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN type = 'transfer' AND accountId = ? THEN amount ELSE 0 END), 0)
      AS balance FROM transactions WHERE accountId = ? OR toAccountId = ?
    ''', [accountId, accountId, accountId, accountId]);
    final balance = (result.first['balance'] as num?)?.toDouble() ?? 0;
    await db.update('accounts', {'balance': balance}, where: 'id = ?', whereArgs: [accountId]);
    await loadAccounts();
  }

  Future<int> insertCategory(Category category) async {
    final db = await _db.database;
    final id = await db.insert('categories', category.toMap()..remove('id'));
    await loadCategories();
    return id;
  }

  Future<int> insertBudget(Budget budget) async {
    final db = await _db.database;
    final id = await db.insert('budgets', budget.toMap()..remove('id'));
    await loadBudgets();
    return id;
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await _db.database;
    await db.update('budgets', budget.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [budget.id]);
    await loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    final db = await _db.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
    await loadBudgets();
  }

  Future<int> insertDebt(Debt debt) async {
    final db = await _db.database;
    final id = await db.insert('debts', debt.toMap()..remove('id'));
    await loadDebts();
    return id;
  }

  Future<void> updateDebt(Debt debt) async {
    final db = await _db.database;
    await db.update('debts', debt.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [debt.id]);
    await loadDebts();
  }

  Future<void> deleteDebt(int id) async {
    final db = await _db.database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
    await loadDebts();
  }

  Future<int> insertSavingsGoal(SavingsGoal goal) async {
    final db = await _db.database;
    final id = await db.insert('savings_goals', goal.toMap()..remove('id'));
    await loadSavingsGoals();
    return id;
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final db = await _db.database;
    await db.update('savings_goals', goal.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [goal.id]);
    await loadSavingsGoals();
  }

  Future<void> deleteSavingsGoal(int id) async {
    final db = await _db.database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    await loadSavingsGoals();
  }

  Future<void> addToSavingsGoal(int goalId, double amount) async {
    final goal = _savingsGoals.firstWhere((g) => g.id == goalId);
    await updateSavingsGoal(goal.copyWith(currentAmount: goal.currentAmount + amount));
  }

  Future<int> insertBazarList(BazarList list) async {
    final db = await _db.database;
    final id = await db.insert('bazar_lists', list.toMap()..remove('id'));
    await loadBazarLists();
    return id;
  }

  Future<void> updateBazarList(BazarList list) async {
    final db = await _db.database;
    await db.update('bazar_lists', list.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [list.id]);
    await loadBazarLists();
  }

  Future<void> deleteBazarList(int id) async {
    final db = await _db.database;
    await db.delete('bazar_items', where: 'listId = ?', whereArgs: [id]);
    await db.delete('bazar_lists', where: 'id = ?', whereArgs: [id]);
    await loadBazarLists();
  }

  Future<List<BazarItem>> getBazarItems(int listId) async {
    final db = await _db.database;
    final maps = await db.query('bazar_items', where: 'listId = ?', whereArgs: [listId]);
    return maps.map((m) => BazarItem.fromMap(m)).toList();
  }

  Future<int> insertBazarItem(BazarItem item) async {
    final db = await _db.database;
    return await db.insert('bazar_items', item.toMap()..remove('id'));
  }

  Future<void> updateBazarItem(BazarItem item) async {
    final db = await _db.database;
    await db.update('bazar_items', item.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteBazarItem(int id) async {
    final db = await _db.database;
    await db.delete('bazar_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertIncomeSource(IncomeSource source) async {
    final db = await _db.database;
    final id = await db.insert('income_sources', source.toMap()..remove('id'));
    await loadIncomeSources();
    return id;
  }

  Future<void> updateIncomeSource(IncomeSource source) async {
    final db = await _db.database;
    await db.update('income_sources', source.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [source.id]);
    await loadIncomeSources();
  }

  Future<void> deleteIncomeSource(int id) async {
    final db = await _db.database;
    await db.delete('income_sources', where: 'id = ?', whereArgs: [id]);
    await loadIncomeSources();
  }

  Future<int> insertRecurringRule(RecurringRule rule) async {
    final db = await _db.database;
    final id = await db.insert('recurring_rules', rule.toMap()..remove('id'));
    await loadRecurringRules();
    return id;
  }

  Future<void> updateRecurringRule(RecurringRule rule) async {
    final db = await _db.database;
    await db.update('recurring_rules', rule.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [rule.id]);
    await loadRecurringRules();
  }

  Future<void> deleteRecurringRule(int id) async {
    final db = await _db.database;
    await db.delete('recurring_rules', where: 'id = ?', whereArgs: [id]);
    await loadRecurringRules();
  }

  List<MapEntry<RecurringRule, Transaction>> getUpcomingRecurring({int limit = 10}) {
    final now = DateTime.now();
    final results = <MapEntry<RecurringRule, Transaction>>[];
    for (final rule in _recurringRules.where((r) => r.isActive)) {
      final tx = _transactions.where((t) => t.id == rule.transactionId).firstOrNull;
      if (tx == null) continue;
      if (rule.nextDate.isAfter(now.subtract(const Duration(days: 1)))) {
        results.add(MapEntry(rule, tx));
      }
    }
    results.sort((a, b) => a.key.nextDate.compareTo(b.key.nextDate));
    return results.take(limit).toList();
  }

  double getExpensesForCategory(int categoryId, int month, int year) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.categoryId == categoryId &&
            !t.date.isBefore(start) &&
            t.date.isBefore(end))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getExpensesForMonth(int month, int year) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            !t.date.isBefore(start) &&
            t.date.isBefore(end))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getIncomeForMonth(int month, int year) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _transactions
        .where((t) =>
            t.type == 'income' &&
            !t.date.isBefore(start) &&
            t.date.isBefore(end))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  List<MapEntry<Category, double>> getTopExpenseCategories(int month, int year, {int limit = 5}) {
    final cats = <int, double>{};
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    for (final t in _transactions) {
      if (t.type == 'expense' &&
          !t.date.isBefore(start) &&
          t.date.isBefore(end) &&
          t.categoryId != null) {
        cats.update(t.categoryId!, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }
    final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final List<MapEntry<Category, double>> result = [];
    for (final entry in sorted.take(limit)) {
      final cat = _categories.firstWhere((c) => c.id == entry.key, orElse: () => Category(name: 'Unknown', type: 'expense'));
      result.add(MapEntry(cat, entry.value));
    }
    return result;
  }

  List<Transaction> getRecentTransactions({int limit = 10}) {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  List<Transaction> getTransactionsForAccount(int accountId) {
    return _transactions
        .where((t) => t.accountId == accountId || t.toAccountId == accountId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> resetAllData() async {
    await _db.resetAllData();
    final db = await _db.database;
    _accounts = (await db.query('accounts', orderBy: 'createdAt ASC')).map((m) => Account.fromMap(m)).toList();
    _categories = (await db.query('categories', orderBy: 'id ASC')).map((m) => Category.fromMap(m)).toList();
    _transactions = (await db.query('transactions', orderBy: 'date DESC')).map((m) => Transaction.fromMap(m)).toList();
    _budgets = (await db.query('budgets')).map((m) => Budget.fromMap(m)).toList();
    _debts = (await db.query('debts', orderBy: 'date DESC')).map((m) => Debt.fromMap(m)).toList();
    _savingsGoals = (await db.query('savings_goals', orderBy: 'createdAt DESC')).map((m) => SavingsGoal.fromMap(m)).toList();
    _incomeSources = (await db.query('income_sources', orderBy: 'id ASC')).map((m) => IncomeSource.fromMap(m)).toList();
    _bazarLists = (await db.query('bazar_lists', orderBy: 'date DESC')).map((m) => BazarList.fromMap(m)).toList();
    _recurringRules = (await db.query('recurring_rules', orderBy: 'nextDate ASC')).map((m) => RecurringRule.fromMap(m)).toList();
    notifyListeners();
  }
}
