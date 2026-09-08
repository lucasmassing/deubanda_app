import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/perfil_musico.dart';

class ProfileViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  PerfilMusico? _perfil;
  PerfilMusico? get perfil => _perfil;

  bool _isFetching = true;
  bool get isFetching => _isFetching;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _cidadeEstado;
  String? get cidadeEstado => _cidadeEstado;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProfileViewModel() {
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _isFetching = false;
      notifyListeners();
      return;
    }

    try {
      final data = await _supabase
          .from('perfis_musicos')
          .select()
          .eq('perfil_id', user.id)
          .maybeSingle();

      if (data != null) {
        _perfil = PerfilMusico.fromJson(data);
        if (_perfil!.perfilCidade != null &&
            _perfil!.perfilCidade!.isNotEmpty) {
          _cidadeEstado = _perfil!.perfilCidade;
        } else if (_perfil!.perfilCep != null &&
            _perfil!.perfilCep!.isNotEmpty) {
          await buscarCep(_perfil!.perfilCep!);
        }
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados do perfil.';
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<bool> salvarPerfil(PerfilMusico perfilAtualizado) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.from('perfis_musicos').upsert(perfilAtualizado.toJson());
      _perfil = perfilAtualizado;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao salvar o perfil.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) {
      _cidadeEstado = null;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          _cidadeEstado = '${data['localidade']} - ${data['uf']}';
        } else {
          _cidadeEstado = 'CEP não encontrado';
        }
      }
    } catch (e) {
      _cidadeEstado = 'Erro ao buscar localização';
    }
    notifyListeners();
  }

  Future<void> fazerLogout() async {
    await _supabase.auth.signOut();
  }
}
