import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.apiClient,
    required this.onSignedIn,
    super.key,
  });

  final ApiClient apiClient;
  final VoidCallback onSignedIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _ownerName = TextEditingController();
  final _shopName = TextEditingController();
  final _phone = TextEditingController();

  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _ownerName.dispose();
    _shopName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = _register
          ? await widget.apiClient.post('/auth/register', {
              'ownerName': _ownerName.text.trim(),
              'shopName': _shopName.text.trim(),
              'phone': _phone.text.trim(),
              'email': _email.text.trim(),
              'password': _password.text,
            })
          : await widget.apiClient.post('/auth/login', {
              'email': _email.text.trim(),
              'password': _password.text,
            });

      final data = response['data'] as Map<String, dynamic>;
      await widget.apiClient.tokenStore.save(
        accessToken: data['accessToken'].toString(),
        refreshToken: data['refreshToken'].toString(),
      );
      widget.onSignedIn();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not connect to the server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Invoice Manager', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    _register ? 'Create your shop workspace' : 'Sign in to your shop workspace',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_register) ...[
                          TextFormField(
                            controller: _ownerName,
                            decoration: const InputDecoration(labelText: 'Owner name'),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _shopName,
                            decoration: const InputDecoration(labelText: 'Shop name'),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Phone'),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password'),
                          validator: (value) => (value == null || value.length < 8) ? 'Minimum 8 characters' : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(_register ? Icons.storefront : Icons.login),
                          label: Text(_register ? 'Create shop' : 'Sign in'),
                        ),
                        TextButton(
                          onPressed: _loading ? null : () => setState(() => _register = !_register),
                          child: Text(_register ? 'Use existing account' : 'Register a new shop'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
