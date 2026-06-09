import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hisabi.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('DROP TABLE IF EXISTS bazar_items');
          await db.execute('DROP TABLE IF EXISTS bazar_lists');
          await db.execute('DROP TABLE IF EXISTS savings_goals');
          await db.execute('DROP TABLE IF EXISTS debts');
          await db.execute('DROP TABLE IF EXISTS budgets');
          await db.execute('DROP TABLE IF EXISTS income_sources');
          await db.execute('DROP TABLE IF EXISTS recurring_rules');
          await db.execute('DROP TABLE IF EXISTS transactions');
          await db.execute('DROP TABLE IF EXISTS categories');
          await db.execute('DROP TABLE IF EXISTS accounts');
          _onCreate(db, newV);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nameBn TEXT,
        type TEXT NOT NULL,
        bankName TEXT,
        balance REAL DEFAULT 0,
        color INTEGER DEFAULT 4283215696,
        icon TEXT DEFAULT 'account_balance',
        isActive INTEGER DEFAULT 1,
        createdAt TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nameBn TEXT,
        type TEXT NOT NULL,
        icon TEXT DEFAULT 'more_horiz',
        color INTEGER DEFAULT 4283215696
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense', 'transfer')),
        categoryId INTEGER,
        accountId INTEGER NOT NULL,
        toAccountId INTEGER,
        date TEXT NOT NULL,
        note TEXT,
        photo TEXT,
        tags TEXT,
        isRecurring INTEGER DEFAULT 0,
        createdAt TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (categoryId) REFERENCES categories(id),
        FOREIGN KEY (accountId) REFERENCES accounts(id),
        FOREIGN KEY (toAccountId) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        frequency TEXT NOT NULL,
        intervalValue INTEGER DEFAULT 1,
        dayOfWeek INTEGER,
        dayOfMonth INTEGER,
        nextDate TEXT NOT NULL,
        endDate TEXT,
        isActive INTEGER DEFAULT 1,
        FOREIGN KEY (transactionId) REFERENCES transactions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE income_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nameBn TEXT,
        categoryId INTEGER,
        accountId INTEGER NOT NULL,
        amount REAL DEFAULT 0,
        frequency TEXT DEFAULT 'one_time',
        nextDate TEXT,
        note TEXT,
        isActive INTEGER DEFAULT 1,
        FOREIGN KEY (categoryId) REFERENCES categories(id),
        FOREIGN KEY (accountId) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount REAL NOT NULL,
        carryOver INTEGER DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personName TEXT NOT NULL,
        phone TEXT,
        amount REAL NOT NULL,
        amountPaid REAL DEFAULT 0,
        type TEXT NOT NULL CHECK(type IN ('owe', 'owed')),
        date TEXT NOT NULL,
        dueDate TEXT,
        note TEXT,
        relatedTransactionId INTEGER,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (relatedTransactionId) REFERENCES transactions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nameBn TEXT,
        targetAmount REAL NOT NULL,
        currentAmount REAL DEFAULT 0,
        deadline TEXT,
        accountId INTEGER,
        icon TEXT DEFAULT 'savings',
        color INTEGER DEFAULT 4283215696,
        priority INTEGER DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (accountId) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bazar_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        totalEstimated REAL DEFAULT 0,
        totalActual REAL,
        isTemplate INTEGER DEFAULT 0,
        accountId INTEGER,
        categoryId INTEGER,
        isCompleted INTEGER DEFAULT 0,
        createdAt TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (accountId) REFERENCES accounts(id),
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bazar_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        listId INTEGER NOT NULL,
        name TEXT NOT NULL,
        nameBn TEXT,
        quantity REAL DEFAULT 1,
        unit TEXT DEFAULT 'pcs',
        priceEstimated REAL DEFAULT 0,
        priceActual REAL,
        isBought INTEGER DEFAULT 0,
        FOREIGN KEY (listId) REFERENCES bazar_lists(id) ON DELETE CASCADE
      )
    ''');

    _seedCategories(db);
    _seedDefaultAccounts(db);
  }

  Future<void> _seedCategories(Database db) async {
    final expenseCats = [
      {'name': 'Food & Groceries', 'nameBn': 'খাবার ও বাজার', 'type': 'expense', 'icon': 'restaurant', 'color': 4284622888},
      {'name': 'House Rent', 'nameBn': 'বাড়ি ভাড়া', 'type': 'expense', 'icon': 'home', 'color': 4283215696},
      {'name': 'Medicine & Health', 'nameBn': 'ওষুধ ও স্বাস্থ্য', 'type': 'expense', 'icon': 'medical_services', 'color': 4294198070},
      {'name': 'Education', 'nameBn': 'পড়াশোনা', 'type': 'expense', 'icon': 'school', 'color': 4280391411},
      {'name': 'Clothing', 'nameBn': 'পোশাক', 'type': 'expense', 'icon': 'checkroom', 'color': 4293458816},
      {'name': 'Transport', 'nameBn': 'যাতায়াত', 'type': 'expense', 'icon': 'directions_bus', 'color': 4289797350},
      {'name': 'Utility Bills', 'nameBn': 'ইউটিলিটি', 'type': 'expense', 'icon': 'bolt', 'color': 4293467747},
      {'name': 'Mobile Recharge', 'nameBn': 'মোবাইল রিচার্জ', 'type': 'expense', 'icon': 'smartphone', 'color': 4288531808},
      {'name': 'Donation', 'nameBn': 'দান', 'type': 'expense', 'icon': 'volunteer_activism', 'color': 4288216960},
      {'name': 'Festival', 'nameBn': 'উৎসব', 'type': 'expense', 'icon': 'celebration', 'color': 4294940672},
      {'name': 'Restaurant', 'nameBn': 'রেস্টুরেন্ট', 'type': 'expense', 'icon': 'local_dining', 'color': 4293467747},
      {'name': 'Child Expenses', 'nameBn': 'শিশু খরচ', 'type': 'expense', 'icon': 'child_care', 'color': 4294940672},
      {'name': 'Personal Care', 'nameBn': 'সাজসজ্জা', 'type': 'expense', 'icon': 'spa', 'color': 4294198070},
      {'name': 'Home Maintenance', 'nameBn': 'বাড়ি মেরামত', 'type': 'expense', 'icon': 'build', 'color': 4289797350},
      {'name': 'Entertainment', 'nameBn': 'বিনোদন', 'type': 'expense', 'icon': 'movie', 'color': 4280391411},
      {'name': 'Online Shopping', 'nameBn': 'অনলাইন শপিং', 'type': 'expense', 'icon': 'shopping_cart', 'color': 4284622888},
      {'name': 'Travel', 'nameBn': 'ভ্রমণ', 'type': 'expense', 'icon': 'flight', 'color': 4283215696},
      {'name': 'Insurance', 'nameBn': 'বীমা', 'type': 'expense', 'icon': 'security', 'color': 4288531808},
      {'name': 'Loan Payment', 'nameBn': 'কিস্তি', 'type': 'expense', 'icon': 'payments', 'color': 4294198070},
      {'name': 'Other', 'nameBn': 'অন্যান্য', 'type': 'expense', 'icon': 'more_horiz', 'color': 4288216960},
    ];

    final incomeCats = [
      {'name': 'Salary', 'nameBn': 'চাকরির বেতন', 'type': 'income', 'icon': 'work', 'color': 4283215696},
      {'name': 'Business', 'nameBn': 'ব্যবসা', 'type': 'income', 'icon': 'business', 'color': 4284622888},
      {'name': 'Freelance', 'nameBn': 'ফ্রিল্যান্স', 'type': 'income', 'icon': 'laptop', 'color': 4280391411},
      {'name': 'House Rent', 'nameBn': 'বাড়ি ভাড়া', 'type': 'income', 'icon': 'home', 'color': 4289797350},
      {'name': 'Investment', 'nameBn': 'বিনিয়োগ', 'type': 'income', 'icon': 'trending_up', 'color': 4283215696},
      {'name': 'Gift', 'nameBn': 'উপহার', 'type': 'income', 'icon': 'card_giftcard', 'color': 4294940672},
      {'name': 'Loan Received', 'nameBn': 'ধার পেয়েছি', 'type': 'income', 'icon': 'account_balance', 'color': 4288531808},
      {'name': 'Other Income', 'nameBn': 'অন্যান্য', 'type': 'income', 'icon': 'add_circle', 'color': 4288216960},
    ];

    final batch = db.batch();
    for (final cat in [...expenseCats, ...incomeCats]) {
      batch.insert('categories', cat);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedDefaultAccounts(Database db) async {
    await db.insert('accounts', {
      'name': 'Cash on Hand',
      'nameBn': 'নগদ',
      'type': 'Cash on Hand',
      'balance': 0,
      'color': 4283215696,
      'icon': 'payments',
    });
    await db.insert('accounts', {
      'name': 'bKash',
      'nameBn': 'বিকাশ',
      'type': 'Mobile Banking',
      'bankName': 'bKash',
      'balance': 0,
      'color': 4284622888,
      'icon': 'smartphone',
    });
    await db.insert('accounts', {
      'name': 'Nagad',
      'nameBn': 'নগদ',
      'type': 'Mobile Banking',
      'bankName': 'Nagad',
      'balance': 0,
      'color': 4294198070,
      'icon': 'smartphone',
    });
  }
}
