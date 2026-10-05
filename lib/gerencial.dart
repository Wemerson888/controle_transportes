import 'package:flutter/material.dart';

import 'clientes_lojas.dart';
import 'motoristas.dart';
import 'abastecimentos_gerente.dart';
import 'relatorio_mensal.dart';
import 'controle_frotas.dart';
import 'dashboard.dart';

// ============================================================
// MENU GERENCIAL
// ============================================================

class GerencialPage extends StatelessWidget {
  const GerencialPage({super.key});

  void abrirClientesLojas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClientesLojasPage(),
      ),
    );
  }

  void abrirMotoristas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MotoristasPage(),
      ),
    );
  }

  void abrirAbastecimentos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AbastecimentosGerentePage(),
      ),
    );
  }

  void abrirDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardPage(),
      ),
    );
  }

  void abrirRelatorios(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RelatorioMensalPage(),
      ),
    );
  }

  void abrirControleFrotas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ControleFrotasPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ÁREA GERENCIAL',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'GERENCIAMENTO',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Controle geral dos transportes',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.local_shipping,
                          size: 38,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                BotaoGerencial(
                  icone: Icons.business,
                  titulo: 'CLIENTES',
                  subtitulo:
                  'Cadastrar clientes e valores de frete',
                  onTap: () => abrirClientesLojas(context),
                ),

                BotaoGerencial(
                  icone: Icons.people,
                  titulo: 'MOTORISTAS',
                  subtitulo:
                  'Consultar e ativar ou desativar motoristas',
                  onTap: () => abrirMotoristas(context),
                ),

                BotaoGerencial(
                  icone: Icons.local_gas_station,
                  titulo: 'ABASTECIMENTOS',
                  subtitulo:
                  'Controlar abastecimentos e valores por caminhão',
                  onTap: () => abrirAbastecimentos(context),
                ),

                BotaoGerencial(
                  icone: Icons.dashboard,
                  titulo: 'DASHBOARD',
                  subtitulo:
                  'Visualizar informações em tempo real',
                  onTap: () => abrirDashboard(context),
                ),

                BotaoGerencial(
                  icone: Icons.assessment,
                  titulo: 'RELATÓRIOS',
                  subtitulo:
                  'Consultar dados e gerar relatórios',
                  onTap: () => abrirRelatorios(context),
                ),

                BotaoGerencial(
                  icone: Icons.local_shipping,
                  titulo: 'CONTROLE DE FROTAS',
                  subtitulo:
                  'Consultar despesas e comprovantes',
                  onTap: () => abrirControleFrotas(context),
                ),

                const SizedBox(height: 15),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'As informações financeiras e de gerenciamento '
                                'ficam disponíveis somente na área gerencial.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BotaoGerencial extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const BotaoGerencial({
    super.key,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: SizedBox(
        height: 88,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icone,
                size: 35,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
