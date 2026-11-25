import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kos_model.dart';

class KosRepositoryException implements Exception {
  final String message;
  const KosRepositoryException([this.message = 'Gagal memuat data, periksa koneksi Anda']);

  @override
  String toString() => message;
}

class KosRepository {
  final SupabaseClient? client;
  final Future<List<Map<String, dynamic>>> Function()? customFetcher;

  KosRepository({
    this.client,
    this.customFetcher,
  });

  SupabaseClient get supabaseClient => client ?? Supabase.instance.client;

  Future<List<KosModel>> getKosList() async {
    try {
      final List<dynamic> data;
      final fetcher = customFetcher;
      if (fetcher != null) {
        data = await fetcher();
      } else {
        data = await supabaseClient
            .from('kos')
            .select()
            .order('created_at', ascending: false);
      }
      return data
          .map((item) => KosModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on KosRepositoryException {
      rethrow;
    } catch (e) {
      debugPrint('SUPABASE_ERROR: $e');
      throw const KosRepositoryException('Gagal memuat data, periksa koneksi Anda');
    }
  }
}
