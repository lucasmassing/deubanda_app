import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Avisa a View para reconstruir a tela
  }

  // Retorna true se o login for bem-sucedido
  Future<bool> fazerLogin(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erro inesperado ao fazer login.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Retorna true se o cadastro for bem-sucedido
  Future<bool> realizarCadastro(
    String name,
    String email,
    String password,
  ) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erro inesperado ao cadastrar.';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
