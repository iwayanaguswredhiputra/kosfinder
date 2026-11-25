import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/kos_provider.dart';
import 'package:provider/provider.dart';

/// Daftar tetap fasilitas sesuai PRD.
const List<String> kFacilitiesList = [
  'Wi-Fi',
  'Kasur',
  'Lemari',
  'Kamar Mandi Dalam',
  'AC',
  'Parkir Motor',
];

/// Daftar tetap tipe kos.
const List<String> kKosTypes = ['Putra', 'Putri', 'Campur'];

/// Menampilkan bottom-sheet filter dan menerapkan perubahan ke [KosProvider].
Future<void> showFilterModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _FilterModal(),
  );
}

class _FilterModal extends StatefulWidget {
  const _FilterModal();

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  late TextEditingController _priceController;
  String? _selectedType;
  Set<String> _selectedFacilities = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<KosProvider>();
    _priceController = TextEditingController(
      text: provider.maxPrice != null ? provider.maxPrice.toString() : '',
    );
    _selectedType = provider.selectedType;
    _selectedFacilities = Set<String>.from(provider.selectedFacilities);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _apply() {
    final raw = _priceController.text.trim();
    final maxPrice = raw.isEmpty ? null : int.tryParse(raw);
    context.read<KosProvider>().setFilter(
          maxPrice: maxPrice,
          type: _selectedType,
          facilities: Set<String>.from(_selectedFacilities),
        );
    Navigator.of(context).pop();
  }

  void _reset() {
    context.read<KosProvider>().resetFilter();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter Kos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // ── Harga Maksimal ────────────────────────────────────────────────
            const Text(
              'Harga Maksimal (Rp)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('maxPriceField'),
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Contoh: 1000000',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // ── Tipe Kos ──────────────────────────────────────────────────────
            const Text(
              'Tipe Kos',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: kKosTypes.map((type) {
                final selected = _selectedType == type;
                return ChoiceChip(
                  key: Key('typeChip_$type'),
                  label: Text(type),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedType = selected ? null : type;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Fasilitas ─────────────────────────────────────────────────────
            const Text(
              'Fasilitas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...kFacilitiesList.map((facility) {
              return CheckboxListTile(
                key: Key('facilityCheck_$facility'),
                title: Text(facility),
                value: _selectedFacilities.contains(facility),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedFacilities.add(facility);
                    } else {
                      _selectedFacilities.remove(facility);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),

            // ── Action Buttons ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('resetFilterButton'),
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Filter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('applyFilterButton'),
                    onPressed: _apply,
                    icon: const Icon(Icons.check),
                    label: const Text('Terapkan'),
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
