import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/perfil_musico.dart';
import '../models/instrumento.dart'; // NOVO IMPORT

class ProfileViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  PerfilMusico? _perfil;
  PerfilMusico? get perfil => _perfil;

  List<Instrumento> _todosInstrumentos = [];
  List<Instrumento> get todosInstrumentos => _todosInstrumentos;

  List<MusicoInstrumento> _meusInstrumentos = [];
  List<MusicoInstrumento> get meusInstrumentos => _meusInstrumentos;

  List<Map<String, dynamic>> _meusGeneros = [];
  List<Map<String, dynamic>> get meusGeneros => _meusGeneros;

  List<String> _horariosDisponiveis = []; // Formato: "Segunda-Manhã"
  List<String> get horariosDisponiveis => _horariosDisponiveis;

  bool _isFetching = true;
  bool get isFetching => _isFetching;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _cidadeEstado;
  String? get cidadeEstado => _cidadeEstado;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProfileViewModel() {
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    await carregarInstrumentosDisponiveis();
    await carregarPerfil();
  }

  // Carrega a lista de todos os instrumentos que cadastramos no SQL
  Future<void> carregarInstrumentosDisponiveis() async {
    try {
      final data = await _supabase
          .from('instrumentos')
          .select()
          .order('instrumento_nome');
      _todosInstrumentos = (data as List)
          .map((json) => Instrumento.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar lista de instrumentos: $e');
    }
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

        // Busca os instrumentos que o usuário toca (fazendo JOIN com a tabela de instrumentos)
        await carregarMeusInstrumentos(user.id);
        await carregarDadosExtras();
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados do perfil.';
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> carregarMeusInstrumentos(String userId) async {
    try {
      final data = await _supabase
          .from('musico_instrumentos')
          .select(
            'musico_id, instrumento_id, instrumento_nivel, instrumentos(instrumento_nome)',
          )
          .eq('musico_id', userId);

      _meusInstrumentos = (data as List)
          .map((json) => MusicoInstrumento.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar meus instrumentos: $e');
    }
  }

  Future<bool> adicionarInstrumento(int instrumentoId, String nivel) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final novoVinculo = MusicoInstrumento(
        musicoId: userId,
        instrumentoId: instrumentoId,
        instrumentoNivel: nivel,
      );

      await _supabase.from('musico_instrumentos').upsert(novoVinculo.toJson());
      await carregarMeusInstrumentos(userId); // Recarrega a lista
      return true;
    } catch (e) {
      _errorMessage =
          'Erro ao adicionar instrumento. Você já pode tê-lo adicionado.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removerInstrumento(int instrumentoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('musico_instrumentos')
          .delete()
          .eq('musico_id', userId)
          .eq('instrumento_id', instrumentoId);

      await carregarMeusInstrumentos(userId); // Recarrega a lista
      return true;
    } catch (e) {
      return false;
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

  void limparDados() {
    _perfil = null;
    _meusInstrumentos = [];
    _cidadeEstado = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fazerLogout() async {
    limparDados(); // Limpa o estado da memória antes de sair
    await _supabase.auth.signOut();
  }

  // disponiblidade semanal e gêneros musicais

  final List<String> _diasSemana = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  final List<String> _turnos = ['Manhã', 'Tarde', 'Noite'];

  List<String> get diasSemana => _diasSemana;
  List<String> get turnos => _turnos;

  // --- NOVOS MÉTODOS ---
  Future<void> carregarDadosExtras() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Carrega Gêneros
      final generosData = await _supabase
          .from('musico_generos')
          .select()
          .eq('perfil_id', userId);
      _meusGeneros = List<Map<String, dynamic>>.from(generosData);

      // Carrega Disponibilidade
      final dispData = await _supabase
          .from('disponibilidade_semanal')
          .select()
          .eq('perfil_id', userId);
      _horariosDisponiveis = (dispData as List)
          .map((d) => '${d['dia_semana']}-${d['turno']}')
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados extras: $e');
    }
  }

  Future<void> alternarHorario(String dia, String turno) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final chave = '$dia-$turno';
    final existe = _horariosDisponiveis.contains(chave);

    try {
      if (existe) {
        await _supabase.from('disponibilidade_semanal').delete().match({
          'perfil_id': userId,
          'dia_semana': dia,
          'turno': turno,
        });
        _horariosDisponiveis.remove(chave);
      } else {
        await _supabase.from('disponibilidade_semanal').insert({
          'perfil_id': userId,
          'dia_semana': dia,
          'turno': turno,
        });
        _horariosDisponiveis.add(chave);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar horário: $e');
    }
  }

  Future<void> salvarGenero(int generoId, bool isPrioritario) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('musico_generos').insert({
        'perfil_id': userId,
        'genero_id': generoId,
        'is_prioritario': isPrioritario,
      });
      await carregarDadosExtras();
    } catch (e) {
      debugPrint('Erro ao salvar gênero: $e');
    }
  }
}
