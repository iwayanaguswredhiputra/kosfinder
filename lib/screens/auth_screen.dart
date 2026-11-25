import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  final AuthProvider? authProvider;

  const AuthScreen({super.key, this.authProvider});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _statusMessage;

  bool get _isLogin => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider? authProvider) async {
    if (!_formKey.currentState!.validate() ||
        authProvider == null ||
        authProvider.isLoading) {
      return;
    }

    setState(() => _statusMessage = null);
    if (_isLogin) {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    if (authProvider.errorMessage != null) return;
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pop(true);
    } else if (!_isLogin) {
      setState(() {
        _statusMessage =
            'Registrasi berhasil. Periksa email Anda untuk verifikasi.';
      });
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Masukkan format email yang valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
    if (value.length < 6) return 'Kata sandi minimal 6 karakter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        widget.authProvider ?? _providerFromContextOrNull(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Akun Pemilik')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    controller: _tabController,
                    onTap: (_) {
                      authProvider?.clearError();
                      setState(() => _statusMessage = null);
                    },
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Registrasi'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const Key('authEmailField'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('authPasswordField'),
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          decoration: const InputDecoration(
                            labelText: 'Kata sandi',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),
                        if (authProvider == null)
                          const Text(
                            'Autentikasi belum dikonfigurasi.',
                            key: Key('authConfigurationError'),
                            style: TextStyle(color: Colors.red),
                          )
                        else
                          AnimatedBuilder(
                            animation: authProvider,
                            builder: (context, _) {
                              final errorMessage = authProvider.errorMessage;
                              if (errorMessage == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  errorMessage,
                                  key: const Key('authErrorMessage'),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_statusMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _statusMessage!,
                              key: const Key('authStatusMessage'),
                            ),
                          ),
                        ListenableBuilder(
                          listenable: authProvider ?? _NoopListenable.instance,
                          builder: (context, _) {
                            final isLoading = authProvider?.isLoading ?? false;
                            return FilledButton(
                              key: const Key('authSubmitButton'),
                              onPressed: authProvider == null || isLoading
                                  ? null
                                  : () => _submit(authProvider),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(_isLogin ? 'Masuk' : 'Daftar'),
                            );
                          },
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
}

AuthProvider? _providerFromContextOrNull(BuildContext context) {
  try {
    return context.read<AuthProvider>();
  } on ProviderNotFoundException {
    return null;
  }
}

class _NoopListenable implements Listenable {
  const _NoopListenable._();

  static const instance = _NoopListenable._();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
