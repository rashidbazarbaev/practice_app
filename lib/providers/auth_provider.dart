import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get uid => _user?.uid;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    _status = user != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authErrorMessage(e.code);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    try {
      final cred = await _authService.registerWithEmail(email, password);
      await _authService.updateDisplayName(name);
      // Create initial Firestore profile
      if (cred.user != null) {
        await _firestoreService.saveSettings(cred.user!.uid, {
          'themeMode': 0,
          'accentColor': 0xFF6C63FF,
        });
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authErrorMessage(e.code);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final cred = await _authService.signInWithGoogle();
      return cred != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('sign_in_failed') || msg.contains('ApiException: 10')) {
        _errorMessage =
            'Google Sign-In: добавьте SHA-1 ключ в Firebase Console.\n'
            'Запустите: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android';
      } else if (msg.contains('network')) {
        _errorMessage = 'Нет подключения к интернету';
      } else if (msg.contains('canceled') || msg.contains('cancelled')) {
        _errorMessage = null; // user cancelled, not an error
        _setLoading(false);
        return false;
      } else {
        _errorMessage = 'Ошибка Google Sign-In: $msg';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordReset(email);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authErrorMessage(e.code);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'invalid-email':
        return 'Некорректный email';
      case 'weak-password':
        return 'Пароль слишком простой (минимум 6 символов)';
      case 'network-request-failed':
        return 'Нет подключения к интернету';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'invalid-credential':
        return 'Неверный email или пароль';
      default:
        return 'Ошибка авторизации ($code)';
    }
  }
}
