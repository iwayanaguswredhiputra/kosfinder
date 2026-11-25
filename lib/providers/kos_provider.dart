import 'package:flutter/foundation.dart';
import '../models/kos_model.dart';
import '../repositories/kos_repository.dart';

class KosProvider extends ChangeNotifier {
  // Repository
  final KosRepository _repository;

  // Core data
  List<KosModel> _kosList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search & filter state
  String _searchQuery = '';
  int? _maxPrice;
  String? _selectedType; // 'Putra', 'Putri', 'Campur'
  Set<String> _selectedFacilities = {};

  // Constructor
  KosProvider({KosRepository? repository})
      : _repository = repository ?? KosRepository();

  // Public getters for raw data
  List<KosModel> get kosList => _kosList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters for UI state
  String get searchQuery => _searchQuery;
  int? get maxPrice => _maxPrice;
  String? get selectedType => _selectedType;
  Set<String> get selectedFacilities => _selectedFacilities;

  // Filtered list based on search and filter criteria
  List<KosModel> get filteredKosList {
    var list = _kosList;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((k) => k.area.toLowerCase().contains(query)).toList();
    }
    if (_maxPrice != null) {
      list = list.where((k) => k.price <= _maxPrice!).toList();
    }
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      list = list.where((k) => k.type == _selectedType).toList();
    }
    if (_selectedFacilities.isNotEmpty) {
      list = list.where((k) => _selectedFacilities.every((f) => k.facilities.contains(f))).toList();
    }
    return list;
  }

  // Mutators
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter({int? maxPrice, String? type, Set<String>? facilities}) {
    _maxPrice = maxPrice;
    _selectedType = type;
    _selectedFacilities = facilities ?? {};
    notifyListeners();
  }

  void resetFilter() {
    _maxPrice = null;
    _selectedType = null;
    _selectedFacilities.clear();
    notifyListeners();
  }

  // Fetch data from repository
  Future<void> fetchKosList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _kosList = await _repository.getKosList();
    } on KosRepositoryException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Gagal memuat data, periksa koneksi Anda';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
