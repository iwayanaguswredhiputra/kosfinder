import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kos_model.dart';

class KosRepositoryException implements Exception {
  final String message;
  const KosRepositoryException([
    this.message = 'Gagal memuat data, periksa koneksi Anda',
  ]);

  @override
  String toString() => message;
}

class KosRepository {
  final SupabaseClient? client;
  final Future<List<Map<String, dynamic>>> Function()? customFetcher;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
  customInserter;
  final Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)?
  customUpdater;
  final Future<void> Function(String)? customDeleter;
  final String? Function()? currentUserIdFetcher;

  KosRepository({
    this.client,
    this.customFetcher,
    this.customInserter,
    this.customUpdater,
    this.customDeleter,
    this.currentUserIdFetcher,
  });

  SupabaseClient get supabaseClient => client ?? Supabase.instance.client;

  String _requireCurrentUserId() {
    final userIdFetcher = currentUserIdFetcher;
    final userId = userIdFetcher != null
        ? userIdFetcher()
        : supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const KosRepositoryException(
        'Pengguna harus login untuk mengelola listing kos',
      );
    }
    return userId;
  }

  Map<String, dynamic> _insertPayload(KosModel kos, String ownerId) {
    final payload = kos.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..['owner_id'] = ownerId;
    return payload;
  }

  Map<String, dynamic> _updatePayload(KosModel kos) {
    return {
      'name': kos.name,
      'area': kos.area,
      'price': kos.price,
      'type': kos.type,
      'facilities': kos.facilities,
      'rooms_available': kos.roomsAvailable,
      'contact_name': kos.contactName,
      'contact_phone': kos.contactPhone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<T> _runCrudOperation<T>(
    Future<T> Function() operation, {
    required String connectionMessage,
    required String dataMessage,
    required String permissionMessage,
  }) async {
    try {
      return await operation();
    } on PostgrestException catch (error) {
      final code = error.code;
      final message = error.message.toLowerCase();
      final isPermissionError =
          code == '42501' ||
          code == '401' ||
          code == '403' ||
          message.contains('row-level security') ||
          message.contains('permission denied') ||
          message.contains('unauthorized') ||
          message.contains('forbidden');
      throw KosRepositoryException(
        isPermissionError ? permissionMessage : dataMessage,
      );
    } catch (_) {
      throw KosRepositoryException(connectionMessage);
    }
  }

  Future<KosModel> addKos(KosModel kos) async {
    final payload = _insertPayload(kos, _requireCurrentUserId());
    return _runCrudOperation(
      () async {
        final inserter = customInserter;
        final data = inserter != null
            ? await inserter(payload)
            : await supabaseClient
                  .from('kos')
                  .insert(payload)
                  .select()
                  .single();
        return KosModel.fromJson(data);
      },
      connectionMessage: 'Tidak dapat menambahkan listing. Periksa koneksi internet Anda, lalu coba lagi.',
      dataMessage: 'Listing tidak dapat ditambahkan. Periksa kembali data yang dimasukkan.',
      permissionMessage: 'Anda tidak memiliki izin untuk menambahkan listing.',
    );
  }

  Future<KosModel> updateKos(KosModel kos) async {
    final payload = _updatePayload(kos);
    return _runCrudOperation(
      () async {
        final updater = customUpdater;
        final data = updater != null
            ? await updater(kos.id, payload)
            : await supabaseClient
                  .from('kos')
                  .update(payload)
                  .eq('id', kos.id)
                  .select()
                  .single();
        return KosModel.fromJson(data);
      },
      connectionMessage: 'Tidak dapat memperbarui listing. Periksa koneksi internet Anda, lalu coba lagi.',
      dataMessage: 'Listing tidak dapat diperbarui. Periksa kembali data yang dimasukkan.',
      permissionMessage:
          'Anda tidak memiliki izin untuk memperbarui listing ini.',
    );
  }

  Future<void> deleteKos(String id) async {
    await _runCrudOperation(
      () async {
        final deleter = customDeleter;
        if (deleter != null) {
          await deleter(id);
          return;
        }
        await supabaseClient
            .from('kos')
            .delete()
            .eq('id', id)
            .select('id')
            .single();
      },
      connectionMessage: 'Tidak dapat menghapus listing. Periksa koneksi internet Anda, lalu coba lagi.',
      dataMessage: 'Listing tidak dapat dihapus. Silakan coba lagi.',
      permissionMessage:
          'Anda tidak memiliki izin untuk menghapus listing ini.',
    );
  }

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
      throw const KosRepositoryException(
        'Gagal memuat data, periksa koneksi Anda',
      );
    }
  }
}
