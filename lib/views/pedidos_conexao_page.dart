import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/matching_viewmodel.dart';

class PedidosConexaoPage extends StatefulWidget {
  const PedidosConexaoPage({super.key});

  @override
  State<PedidosConexaoPage> createState() => _PedidosConexaoPageState();
}

class _PedidosConexaoPageState extends State<PedidosConexaoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchingViewModel>().carregarPedidosRecebidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MatchingViewModel>();
    final pedidos = viewModel.pedidosRecebidos;

    return Scaffold(
      appBar: AppBar(title: const Text('Convites Recebidos')),
      body: pedidos.isEmpty
          ? const Center(child: Text('Você não tem novos convites no momento.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                // Os dados do músico que enviou o convite:
                final remetente = pedido['perfis_musicos'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    remetente['perfil_nome'] ?? 'Músico',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    remetente['perfil_cidade'] ??
                                        'Localização não informada',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          remetente['perfil_bio'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => viewModel.responderPedido(
                                pedido['match_id'],
                                'RECUSADO',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Recusar'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => viewModel.responderPedido(
                                pedido['match_id'],
                                'ACEITO',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Aceitar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
