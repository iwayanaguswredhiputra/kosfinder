import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/kos_model.dart';

class KosDetailScreen extends StatelessWidget {
  final KosModel kos;

  const KosDetailScreen({
    super.key,
    required this.kos,
  });

  String _formatPrice(int price) {
    final str = price.toString();
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(regExp, (Match m) => '${m[1]}.');
    return 'Rp $formatted / bulan';
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'putri':
        return Colors.pink.shade700;
      case 'putra':
        return Colors.blue.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  void _copyContact(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: kos.contactPhone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor WhatsApp berhasil disalin'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = kos.isAvailable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    kos.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTypeColor(kos.type).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getTypeColor(kos.type).withAlpha(120),
                    ),
                  ),
                  child: Text(
                    kos.type,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(kos.type),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    kos.area,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harga Sewa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(kos.price),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAvailable
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable
                                ? 'Sisa ${kos.roomsAvailable} Kamar'
                                : 'Penuh',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Fasilitas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (kos.facilities.isEmpty)
              Text(
                'Tidak ada fasilitas khusus yang dicantumkan.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kos.facilities.map((facility) {
                  return Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    label: Text(facility),
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
            const SizedBox(height: 28),
            Text(
              'Kontak Pemilik',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        kos.contactName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          kos.contactPhone,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _copyContact(context),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Salin Nomor'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
