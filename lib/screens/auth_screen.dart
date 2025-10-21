import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _selectedAuthType;
  final TextEditingController _pinController = TextEditingController();
  bool _isBiometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthSettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthSettings() async {
    final authType = await AuthService.getAuthType();
    final isBiometricAvailable = await AuthService.isBiometricAvailable();
    
    setState(() {
      _selectedAuthType = authType;
      _isBiometricAvailable = isBiometricAvailable;
      _isLoading = false;
    });
  }

  Future<void> _authenticate() async {
    if (_selectedAuthType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оберіть тип аутентифікації')),
      );
      return;
    }

    bool authenticated = false;

    switch (_selectedAuthType) {
      case 'biometric':
        authenticated = await AuthService.authenticateWithBiometric();
        break;
      case 'pin':
        if (_pinController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Введіть PIN')),
          );
          return;
        }
        authenticated = await AuthService.authenticateWithPin(_pinController.text);
        break;
      case 'none':
        authenticated = true;
        break;
    }

    if (authenticated) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аутентифікація не пройшла')),
      );
    }
  }

  Future<void> _saveAuthSettings() async {
    if (_selectedAuthType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оберіть тип аутентифікації')),
      );
      return;
    }

    if (_selectedAuthType == 'pin' && _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть PIN')),
      );
      return;
    }

    await AuthService.setAuthType(_selectedAuthType!);
    await AuthService.setAuthEnabled(_selectedAuthType != 'none');

    if (_selectedAuthType == 'pin') {
      await AuthService.setPin(_pinController.text);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Налаштування збережено')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аутентифікація'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Оберіть тип аутентифікації:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Без аутентифікації'),
              subtitle: const Text('Доступ без захисту'),
              value: 'none',
              groupValue: _selectedAuthType,
              onChanged: (value) {
                setState(() {
                  _selectedAuthType = value;
                });
              },
            ),
            if (_isBiometricAvailable)
              RadioListTile<String>(
                title: const Text('Біометрія'),
                subtitle: const Text('Відбиток пальця або Face ID'),
                value: 'biometric',
                groupValue: _selectedAuthType,
                onChanged: (value) {
                  setState(() {
                    _selectedAuthType = value;
                  });
                },
              ),
            RadioListTile<String>(
              title: const Text('PIN'),
              subtitle: const Text('Чотиризначний код'),
              value: 'pin',
              groupValue: _selectedAuthType,
              onChanged: (value) {
                setState(() {
                  _selectedAuthType = value;
                });
              },
            ),
            if (_selectedAuthType == 'pin') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  hintText: '1234',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Аутентифікуватися'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveAuthSettings,
                    child: const Text('Зберегти налаштування'),
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
