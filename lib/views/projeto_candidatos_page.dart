import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/projeto_viewmodel.dart';
import '../models/projeto.dart';

class ProjetoCandidatosPage extends StatefulWidget {
  final Projeto projeto;

  const ProjetoCandidatosPage({super.key, required this.projeto});

  @override
  State<ProjetoCandidatosPage> createState() => _ProjetoCandidatosPageState();
}

class _ProjetoCandidatosPageState extends State<ProjetoCandidatosPage> {
  late Future<List<Map<String, dynamic>>> _futureCandidatos;

  @override
  void initState() {
    super.initState();
    // Inicia a busca dos candidatos assim que a tela abre
    _futureCandidatos = context
        .read<ProjetoViewModel>()
        .buscarCandidatosDoProjeto(widget.projeto.projetoId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatos da Vaga')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCandidatos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar candidatos.'));
          }

          final candidatos = snapshot.data!;
          if (candidatos.isEmpty) {
            return const Center(child: Text('Ninguém se candidatou ainda.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: candidatos.length,
            itemBuilder: (context, index) {
              final item = candidatos[index];
              final perfil = item['perfis_musicos']; // Dados vindos do Join
              final status = item['candidatura_status'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    perfil['perfil_nome'] ?? 'Músico',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perfil['perfil_cidade'] ?? 'Localização não informada',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: status == 'PENDENTE'
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  trailing: OutlinedButton(
                    onPressed: () {
                      // Futuro: Avaliar o músico e mudar o status para ACEITO
                    },
                    child: const Text('Avaliar'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
