import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../home/dashboard_screen.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  const PinScreen({super.key, this.isSetup = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _showConfirm = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                widget.isSetup ? 'Set PIN' : 'Enter PIN',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSetup ? 'Choose a 4-digit PIN' : 'Enter your PIN to unlock',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 16),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '_ _ _ _',
                  hintStyle: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 16,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              if (widget.isSetup && _showConfirm) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 16),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '_ _ _ _',
                    hintStyle: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submit(settings),
                  child: Text(widget.isSetup ? 'Set PIN' : 'Unlock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(SettingsProvider settings) {
    if (widget.isSetup) {
      if (_pinCtrl.text.length != 4) {
        setState(() => _error = 'PIN must be 4 digits');
        return;
      }
      if (!_showConfirm) {
        setState(() {
          _showConfirm = true;
          _error = null;
        });
        return;
      }
      if (_pinCtrl.text != _confirmCtrl.text) {
        setState(() => _error = 'PINs do not match');
        return;
      }
      settings.setPin(_pinCtrl.text);
      Navigator.pop(context);
    } else {
      if (!settings.verifyPin(_pinCtrl.text)) {
        setState(() => _error = 'Wrong PIN');
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    }
  }
}
