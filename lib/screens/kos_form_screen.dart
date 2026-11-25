import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/kos_model.dart';
import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import '../widgets/filter_modal.dart';

class KosFormScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const KosFormScreen({super.key, required this.authProvider});

  @override
  State<KosFormScreen> createState() => _KosFormScreenState();
}

class _KosFormScreenState extends State<KosFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final Set<String> _selectedFacilities = {};
  String? _selectedType;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  String? _nonNegativeIntegerValidator(String? value, String label) {
    final requiredError = _requiredValidator(value, label);
    if (requiredError != null) return requiredError;
    if (int.tryParse(value!.trim()) == null) {
      return '$label harus berupa bilangan bulat';
    }
    if (int.parse(value.trim()) < 0) {
      return '$label tidak boleh negatif';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ownerId = widget.authProvider.user?.id;
    if (ownerId == null) {
      setState(() {
        _errorMessage = 'Silakan masuk untuk menambahkan listing kos';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final kos = KosModel(
      id: '',
      ownerId: ownerId,
      name: _nameController.text.trim(),
      area: _areaController.text.trim(),
      price: int.parse(_priceController.text.trim()),
      type: _selectedType!,
      facilities: List.unmodifiable(_selectedFacilities),
      roomsAvailable: int.parse(_roomsController.text.trim()),
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
    );

    try {
      await context.read<KosProvider>().addKos(kos);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal menyimpan listing: $error';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Kos')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('kosNameField'),
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama kos'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _requiredValidator(value, 'Nama kos'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('kosAreaField'),
                  controller: _areaController,
                  decoration: const InputDecoration(labelText: 'Area/Alamat'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      _requiredValidator(value, 'Area/Alamat'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('kosPriceField'),
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga bulanan (Rp)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
                  ],
                  validator: (value) =>
                      _nonNegativeIntegerValidator(value, 'Harga bulanan'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('kosTypeField'),
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Tipe kos'),
                  items: kKosTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (type) => setState(() => _selectedType = type),
                  validator: (type) =>
                      type == null ? 'Tipe kos wajib dipilih' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fasilitas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...kFacilitiesList.map(
                  (facility) => CheckboxListTile(
                    key: Key('kosFacility_$facility'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(facility),
                    value: _selectedFacilities.contains(facility),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedFacilities.add(facility);
                        } else {
                          _selectedFacilities.remove(facility);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('kosRoomsField'),
                  controller: _roomsController,
                  decoration: const InputDecoration(labelText: 'Sisa kamar'),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
                  ],
                  validator: (value) =>
                      _nonNegativeIntegerValidator(value, 'Sisa kamar'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('kosContactNameField'),
                  controller: _contactNameController,
                  decoration: const InputDecoration(labelText: 'Nama kontak'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      _requiredValidator(value, 'Nama kontak'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('kosContactPhoneField'),
                  controller: _contactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      _requiredValidator(value, 'Nomor WhatsApp'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    key: const Key('kosFormErrorMessage'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('kosSaveButton'),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
