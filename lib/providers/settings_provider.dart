import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _currencyCode = 'BDT';
  String _currencySymbol = '৳';
  String? _pinHash;
  bool _pinEnabled = false;

  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String? get pinHash => _pinHash;
  bool get pinEnabled => _pinEnabled;

  static const _currencyCodeKey = 'currency_code';
  static const _currencySymbolKey = 'currency_symbol';
  static const _pinHashKey = 'pin_hash';
  static const _pinEnabledKey = 'pin_enabled';

  static const Map<String, String> currencies = {
    'BDT': '৳',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'CNY': '¥',
    'AED': 'د.إ',
    'SAR': '﷼',
    'MYR': 'RM',
    'SGD': 'S\$',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString(_currencyCodeKey) ?? 'BDT';
    _currencySymbol = prefs.getString(_currencySymbolKey) ?? '৳';
    _pinHash = prefs.getString(_pinHashKey);
    _pinEnabled = prefs.getBool(_pinEnabledKey) ?? false;
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = code;
    _currencySymbol = currencies[code] ?? '৳';
    await prefs.setString(_currencyCodeKey, code);
    await prefs.setString(_currencySymbolKey, _currencySymbol);
    notifyListeners();
  }

  String formatAmount(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final formatted = formatter.format(amount);
    if (showSymbol) return '$_currencySymbol$formatted';
    return formatted;
  }

  Future<bool> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    _pinHash = hash;
    _pinEnabled = true;
    await prefs.setString(_pinHashKey, hash);
    await prefs.setBool(_pinEnabledKey, true);
    notifyListeners();
    return true;
  }

  bool verifyPin(String pin) {
    if (_pinHash == null) return false;
    return _hashPin(pin) == _pinHash;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    _pinHash = null;
    _pinEnabled = false;
    await prefs.remove(_pinHashKey);
    await prefs.setBool(_pinEnabledKey, false);
    notifyListeners();
  }

  String _hashPin(String pin) {
    int h = 0;
    for (int i = 0; i < pin.length; i++) {
      h = 31 * h + pin.codeUnitAt(i);
    }
    return h.toRadixString(16);
  }
}
