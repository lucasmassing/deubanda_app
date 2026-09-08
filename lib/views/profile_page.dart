import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../models/perfil_musico.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _bioController = TextEditingController();
  final _cepController = TextEditingController();
  final _objetivoController = TextEditingController();
  final _referenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProfileViewModel>();
      if (viewModel.perfil != null) {
        _nomeController.text = viewModel.perfil!.perfilNome;
        _bioController.text = viewModel.perfil!.perfilBio ?? '';
        _cepController.text = viewModel.perfil!.perfilCep ?? '';
        _objetivoController.text = viewModel.perfil!.perfilObjetivo ?? '';
        _referenciaController.text =
            viewModel.perfil!.perfilArtistaReferencia ?? '';
      }
    });
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final viewModel = context.read<ProfileViewModel>();

    final perfil = PerfilMusico(
      perfilId: userId,
      perfilNome: _nomeController.text.trim(),
      perfilBio: _bioController.text.trim(),
      perfilCep: _cepController.text.trim(),
      perfilCoordenadas: null,
      perfilCidade: viewModel.cidadeEstado,
      perfilObjetivo: _objetivoController.text.trim(),
      perfilArtistaReferencia: _referenciaController.text.trim(),
    );

    final sucesso = await viewModel.salvarPerfil(perfil);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Erro ao salvar o perfil.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sair() async {
    await context.read<ProfileViewModel>().fazerLogout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  // Modal para adicionar um novo instrumento
  void _mostrarModalAdicionarInstrumento(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    int? instrumentoSelecionado;
    String nivelSelecionado = 'Iniciante';
    final niveis = ['Iniciante', 'Intermediário', 'Avançado', 'Profissional'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adicionar Instrumento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Instrumento',
                      border: OutlineInputBorder(),
                    ),
                    value: instrumentoSelecionado,
                    items: viewModel.todosInstrumentos.map((inst) {
                      return DropdownMenuItem(
                        value: inst.instrumentoId,
                        child: Text(inst.instrumentoNome),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => instrumentoSelecionado = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Nível de Proficiência',
                      border: OutlineInputBorder(),
                    ),
                    value: nivelSelecionado,
                    items: niveis.map((nivel) {
                      return DropdownMenuItem(value: nivel, child: Text(nivel));
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => nivelSelecionado = val!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (instrumentoSelecionado != null) {
                          Navigator.pop(context); // Fecha o modal
                          final sucesso = await viewModel.adicionarInstrumento(
                            instrumentoSelecionado!,
                            nivelSelecionado,
                          );
                          if (!sucesso && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(viewModel.errorMessage ?? 'Erro'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    if (viewModel.isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _sair,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome ou Nome Artístico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Biografia',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cepController,
                        decoration: const InputDecoration(
                          labelText: 'CEP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        onChanged: (value) {
                          if (value.length == 8) viewModel.buscarCep(value);
                        },
                      ),
                      if (viewModel.cidadeEstado != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            viewModel.cidadeEstado!,
                            style: TextStyle(
                              color: viewModel.cidadeEstado!.contains('Erro')
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _objetivoController,
                        decoration: const InputDecoration(
                          labelText: 'Objetivo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.track_changes),
                        ),
                        maxLength: 30,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenciaController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Artistas de Referência',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.star),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading ? null : _salvarDados,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: viewModel.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Salvar Dados Básicos',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(thickness: 2),
                ),

                // SEÇÃO DE INSTRUMENTOS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Meus Instrumentos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.deepPurple,
                        size: 32,
                      ),
                      onPressed: () =>
                          _mostrarModalAdicionarInstrumento(context, viewModel),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (viewModel.meusInstrumentos.isEmpty)
                  const Text(
                    'Nenhum instrumento adicionado. Clique no "+" para adicionar.',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: viewModel.meusInstrumentos.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.meusInstrumentos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.music_note,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            item.instrumentoNome ?? 'Desconhecido',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Nível: ${item.instrumentoNivel ?? "Não informado"}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => viewModel.removerInstrumento(
                              item.instrumentoId,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
