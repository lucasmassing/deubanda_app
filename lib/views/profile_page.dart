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
      // O banco espera REAL para coordenadas, manteremos null até integrar o GPS
      perfilCoordenadas: null,
      perfilCidade:
          viewModel.cidadeEstado, // Captura a cidade resolvida pelo ViaCEP
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome ou Nome Artístico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Biografia (Fale sobre sua experiência)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cepController,
                    decoration: const InputDecoration(
                      labelText: 'CEP (Apenas números)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    onChanged: (value) {
                      if (value.length == 8) {
                        viewModel.buscarCep(value);
                      }
                    },
                  ),
                  if (viewModel.cidadeEstado != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        left: 4.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        viewModel.cidadeEstado!,
                        style: TextStyle(
                          color:
                              viewModel.cidadeEstado!.contains('Erro') ||
                                  viewModel.cidadeEstado!.contains(
                                    'não encontrado',
                                  )
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
                      labelText: 'Objetivo (Ex: Formar banda, Freelance)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.track_changes),
                    ),
                    maxLength: 30, // Limite imposto pelo VARCHAR(30) no banco
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
                  const SizedBox(height: 32),
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
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Salvar Perfil',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
