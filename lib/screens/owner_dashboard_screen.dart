import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';

class OwnerDashboardScreen extends StatelessWidget {
  final AuthProvider authProvider;

  const OwnerDashboardScreen({super.key, required this.authProvider});

  Future<void> _signOut(BuildContext context) async {
    await authProvider.signOut();
    if (!context.mounted || authProvider.errorMessage != null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kos Saya'),
        actions: [
          TextButton.icon(
            key: const Key('ownerLogoutButton'),
            onPressed: authProvider.isLoading ? null : () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home_work_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Anda belum memiliki listing kos',
                key: Key('ownerEmptyStateMessage'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur tambah kos akan segera tersedia.'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Kos Sekarang'),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: authProvider,
                builder: (context, _) {
                  final errorMessage = authProvider.errorMessage;
                  if (errorMessage == null) return const SizedBox.shrink();
                  return Text(
                    errorMessage,
                    key: const Key('ownerDashboardErrorMessage'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
