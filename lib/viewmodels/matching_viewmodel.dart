import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchingViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _musicosFeed = [];
  List<Map<String, dynamic>> get musicosFeed => _musicosFeed;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MatchingViewModel() {
    carregarFeed();
  }

  Future<void> carregarFeed() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Busca todos os músicos (menos o logado) e traz os instrumentos junto
      final data = await _supabase
          .from('perfis_musicos')
          .select('''
            perfil_id, 
            perfil_nome, 
            perfil_cidade, 
            perfil_bio, 
            perfil_objetivo,
            musico_instrumentos (
              instrumento_nivel, 
              instrumentos(instrumento_nome)
            )
          ''')
          .neq('perfil_id', userId);

      _musicosFeed = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Erro ao carregar feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enviarMatch(String musicoDestinoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Verifica se já enviou match antes para evitar duplicidade
      final existente = await _supabase
          .from('matchings')
          .select()
          .eq('musico_origem_id', userId)
          .eq('musico_destino_id', musicoDestinoId)
          .maybeSingle();

      if (existente != null) return false;

      // Cria a solicitação
      await _supabase.from('matchings').insert({
        'musico_origem_id': userId,
        'musico_destino_id': musicoDestinoId,
        'match_status': 'PENDENTE',
      });

      // Remove o músico da tela
      _musicosFeed.removeWhere((m) => m['perfil_id'] == musicoDestinoId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Erro ao enviar match: $e');
      return false;
    }
  }
}
