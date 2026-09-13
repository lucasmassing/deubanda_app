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
}
