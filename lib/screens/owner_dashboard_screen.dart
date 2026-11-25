import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import '../widgets/kos_card.dart';
import 'kos_form_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const OwnerDashboardScreen({super.key, required this.authProvider});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late final KosProvider _kosProvider;

  @override
  void initState() {
    super.initState();
    _kosProvider = context.read<KosProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kosProvider.fetchKosList();
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await widget.authProvider.signOut();
    if (!context.mounted || widget.authProvider.errorMessage != null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openKosForm(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => KosFormScreen(authProvider: widget.authProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kos Saya'),
        actions: [
          IconButton(
            key: const Key('ownerAddKosButton'),
            tooltip: 'Tambah Kos',
            onPressed: () => _openKosForm(context),
            icon: const Icon(Icons.add),
          ),
          TextButton.icon(
            key: const Key('ownerLogoutButton'),
            onPressed: widget.authProvider.isLoading
                ? null
                : () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_kosProvider, widget.authProvider]),
        builder: (context, _) {
          if (_kosProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_kosProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _kosProvider.errorMessage!,
                      key: const Key('ownerDashboardErrorMessage'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _kosProvider.fetchKosList,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final ownerId = widget.authProvider.user?.id;
          final ownerKos = ownerId == null
              ? const []
              : _kosProvider.kosList
                    .where((kos) => kos.ownerId == ownerId)
                    .toList();

          if (ownerKos.isEmpty) {
            return Center(
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
                      onPressed: () => _openKosForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Kos Sekarang'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            key: const Key('ownerKosList'),
            itemCount: ownerKos.length,
            itemBuilder: (context, index) => KosCard(kos: ownerKos[index]),
          );
        },
      ),
    );
  }
}
