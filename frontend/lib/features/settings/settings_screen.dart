import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.apiClient,
    required this.onSignedOut,
    super.key,
  });

  final ApiClient apiClient;
  final VoidCallback onSignedOut;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Map<String, dynamic>> _future;
  final _shopName = TextEditingController();
  final _taxRate = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _shopName.dispose();
    _taxRate.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await widget.apiClient.get('/auth/me');
    final shop = response['data'] as Map<String, dynamic>;
    _shopName.text = shop['shopName']?.toString() ?? '';
    _taxRate.text = (shop['taxRate'] ?? 0).toString();
    return shop;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.apiClient.patch('/auth/shop', {
        'shopName': _shopName.text.trim(),
        'taxRate': double.tryParse(_taxRate.text) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final refreshToken = await widget.apiClient.tokenStore.refreshToken;
    if (refreshToken != null) {
      try {
        await widget.apiClient.post('/auth/logout', {'refreshToken': refreshToken});
      } catch (_) {
        // Local sign out should still succeed if the token is already invalid.
      }
    }
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _shopName,
                      decoration: const InputDecoration(labelText: 'Shop name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _taxRate,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tax rate'),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: snapshot.connectionState == ConnectionState.waiting || _saving ? null : _save,
                      icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text('Save settings'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }
}
