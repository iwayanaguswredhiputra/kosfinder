import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';
import '../utils/network_error.dart';

class AuthProvider extends ChangeNotifier {
  static const _invalidCredentialsMessage = 'Email atau kata sandi tidak valid';
  static const _emailAlreadyRegisteredMessage = 'Email sudah terdaftar';
  static const _signUpFailurePrefix = 'Gagal mendaftar: ';
  static const _networkErrorMessage =
      'Koneksi internet terputus, silakan coba beberapa saat lagi';

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _authStateSubscription;

  Session? _session;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    _authStateSubscription = _repository.authStateChanges.listen(
      _handleAuthState,
      onError: _handleAuthStateError,
    );
  }

  Session? get session => _session;
  User? get user => _session?.user;
  bool get isAuthenticated => _session != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> signUp({required String email, required String password}) async {
    await _runAuthRequest(
      () => _repository.signUp(email: email, password: password),
      operation: _AuthOperation.signUp,
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _runAuthRequest(
      () => _repository.signIn(email: email, password: password),
      operation: _AuthOperation.signIn,
    );
  }

  Future<void> signOut() async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signOut();
      _session = null;
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _runAuthRequest(
    Future<AuthResponse> Function() request, {
    required _AuthOperation operation,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await request();
      _session = response.session;
    } catch (error) {
      _errorMessage = _messageFor(error, operation: operation);
    } finally {
      _setLoading(false);
    }
  }

  String _messageFor(Object error, {_AuthOperation? operation}) {
    if (isNetworkError(error)) {
      return _networkErrorMessage;
    }
    if (error is AuthException) {
      if (operation == _AuthOperation.signIn) {
        return _invalidCredentialsMessage;
      }
      if (operation == _AuthOperation.signUp) {
        if (_isDuplicateEmailError(error)) {
          return _emailAlreadyRegisteredMessage;
        }
        return '$_signUpFailurePrefix${error.message}';
      }
      return error.message;
    }
    return error.toString();
  }

  bool _isDuplicateEmailError(AuthException error) {
    final code = error.code?.toLowerCase();
    if (code == 'user_already_exists' || code == 'email_exists') {
      return true;
    }

    final message = error.message.toLowerCase();
    return message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('already in use');
  }

  void _handleAuthState(AuthState state) {
    _session = state.session;
    notifyListeners();
  }

  void _handleAuthStateError(Object error) {
    _errorMessage = _messageFor(error);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}

enum _AuthOperation { signUp, signIn }
