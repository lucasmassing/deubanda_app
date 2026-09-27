import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/projeto.dart';

class ProjetoViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Projeto> _projetosAtivos = [];
  List<Projeto> get projetosAtivos => _projetosAtivos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProjetoViewModel() {
    carregarProjetos();
  }

  Future<void> carregarProjetos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('projetos')
          .select()
          .eq('projeto_status', 'ATIVO')
          .order('projeto_titulo');

      _projetosAtivos = (data as List)
          .map((json) => Projeto.fromJson(json))
          .toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar projetos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> criarProjeto(Projeto projeto) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('projetos').insert(projeto.toJson());
      await carregarProjetos(); // Recarrega a lista após criar
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar projeto.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // fluxo de candidaturas
  Future<bool> candidatarSe(String projetoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Verifica se já existe uma candidatura deste usuário para esta vaga
      final existente = await _supabase
          .from('candidaturas')
          .select()
          .eq('candidato_id', userId)
          .eq('projeto_id', projetoId)
          .maybeSingle();

      if (existente != null) {
        _errorMessage = 'Você já se candidatou a esta vaga!';
        return false;
      }

      // 2. Insere a nova candidatura
      await _supabase.from('candidaturas').insert({
        'candidato_id': userId,
        'projeto_id': projetoId,
      });

      return true;
    } catch (e) {
      _errorMessage = 'Erro ao enviar candidatura.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> buscarCandidatosDoProjeto(
    String projetoId,
  ) async {
    try {
      final data = await _supabase
          .from('candidaturas')
          .select('''
            candidatura_id,
            candidatura_status,
            candidatura_data,
            perfis_musicos (
              perfil_nome,
              perfil_cidade,
              perfil_bio
            )
          ''')
          .eq('projeto_id', projetoId)
          .order('candidatura_data', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Erro ao buscar candidatos: $e');
      return [];
    }
  }
}
