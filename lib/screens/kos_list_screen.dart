import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import '../widgets/kos_card.dart';
import '../widgets/filter_modal.dart';
import 'about_screen.dart';
import 'auth_screen.dart';
import 'kos_detail_screen.dart';

class KosListScreen extends StatefulWidget {
  const KosListScreen({super.key});

  @override
  State<KosListScreen> createState() => _KosListScreenState();
}

class _KosListScreenState extends State<KosListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KosProvider>().fetchKosList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KosFinder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Filter button
          Consumer<KosProvider>(
            builder: (context, provider, _) {
              final hasFilter = provider.maxPrice != null ||
                  (provider.selectedType?.isNotEmpty ?? false) ||
                  provider.selectedFacilities.isNotEmpty;
              return IconButton(
                key: const Key('filterButton'),
                icon: Icon(
                  hasFilter ? Icons.filter_list : Icons.filter_list_outlined,
                ),
                tooltip: 'Filter',
                onPressed: () => showFilterModal(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Aplikasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          IconButton(
            key: const Key('ownerAccountButton'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Akun Pemilik',
            onPressed: () {
              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AuthScreen(
                    authProvider: _providerFromContextOrNull(context),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              key: const Key('searchField'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan area...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Consumer<KosProvider>(
                  builder: (context, provider, _) {
                    return provider.searchQuery.isNotEmpty
                        ? IconButton(
                            key: const Key('clearSearchButton'),
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : const SizedBox.shrink();
                  },
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                context.read<KosProvider>().setSearchQuery(value);
              },
            ),
          ),

          // ── Active filter chip summary ────────────────────────────────────
          Consumer<KosProvider>(
            builder: (context, provider, _) {
              final hasFilter = provider.maxPrice != null ||
                  (provider.selectedType?.isNotEmpty ?? false) ||
                  provider.selectedFacilities.isNotEmpty;
              if (!hasFilter) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, size: 16),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Filter aktif',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.resetFilter(),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── List Area ────────────────────────────────────────────────────
          Expanded(
            child: Consumer<KosProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_outlined,
                              size: 64, color: Colors.grey.shade500),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.fetchKosList(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filtered = provider.filteredKosList;

                // Empty state: search no match
                if (filtered.isEmpty && provider.searchQuery.isNotEmpty) {
                  return Center(
                    key: const Key('emptySearchState'),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada kos yang ditemukan di area ini',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Empty state: filter no match
                final hasFilter = provider.maxPrice != null ||
                    (provider.selectedType?.isNotEmpty ?? false) ||
                    provider.selectedFacilities.isNotEmpty;
                if (filtered.isEmpty && hasFilter) {
                  return Center(
                    key: const Key('emptyFilterState'),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_list_off,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada kos yang cocok dengan kriteria filter Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('resetFilterFromEmpty'),
                            onPressed: () => provider.resetFilter(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Filter'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Empty state: no data at all
                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchKosList(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_work_outlined,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada kos yang tersedia',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchKosList(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final kos = filtered[index];
                      return KosCard(
                        kos: kos,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KosDetailScreen(kos: kos),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
