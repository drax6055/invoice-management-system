import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/storage/token_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/app_shell.dart';

class InvoiceApp extends StatefulWidget {
  const InvoiceApp({super.key});

  @override
  State<InvoiceApp> createState() => _InvoiceAppState();
}

class _InvoiceAppState extends State<InvoiceApp> {
  late final TokenStore _tokenStore;
  late final ApiClient _apiClient;
  bool _loading = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _tokenStore = TokenStore();
    _apiClient = ApiClient(tokenStore: _tokenStore);
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _tokenStore.accessToken;
    if (!mounted) return;
    setState(() {
      _signedIn = token != null && token.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _handleSignedIn() async {
    if (!mounted) return;
    setState(() => _signedIn = true);
  }

  Future<void> _handleSignedOut() async {
    await _tokenStore.clear();
    if (!mounted) return;
    setState(() => _signedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _loading
          ? const _BootScreen()
          : _signedIn
              ? AppShell(apiClient: _apiClient, onSignedOut: _handleSignedOut)
              : AuthScreen(apiClient: _apiClient, onSignedIn: _handleSignedIn),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
