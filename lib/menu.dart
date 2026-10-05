import 'package:flutter/material.dart';

import 'abastecimento.dart';
import 'relatorio_despesas.dart';
import 'selecao_caminhao.dart';
import 'fretes_comissoes.dart';
import 'diario_bordo.dart';
import 'controle_km.dart';

// ============================================================
// MENU DO MOTORISTA
// ============================================================

class MenuMotoristaPage extends StatelessWidget {
  final String nomeMotorista;
  final Caminhao caminhao;

  const MenuMotoristaPage({
    super.key,
    required this.nomeMotorista,
    required this.caminhao,
  });

  // ==========================================================
  // RELATÓRIO DE DESPESAS
  // ==========================================================

  void abrirRelatorio(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RelatorioDespesasPage(
          motorista: nomeMotorista,
          caminhao:
          '${caminhao.frota} - ${caminhao.placa}',
        ),
      ),
    );
  }

  // ==========================================================
  // HISTÓRICO
  // ==========================================================

  void abrirHistorico(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoricoDespesasPage(
          motorista: nomeMotorista,
          caminhao:
          '${caminhao.frota} - ${caminhao.placa}',
        ),
      ),
    );
  }

  // ==========================================================
  // ABASTECIMENTO
  // ==========================================================

  void abrirAbastecimento(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AbastecimentoPage(
          placaInicial: caminhao.placa,
          modeloInicial: caminhao.modelo,
          motoristaInicial: nomeMotorista,
        ),
      ),
    );
  }

  // ==========================================================
  // CONTROLE DE KM
  // ==========================================================

  void abrirControleKm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ControleKmPage(
          motorista: nomeMotorista,
          caminhao: caminhao,
        ),
      ),
    );
  }

  // ==========================================================
  // FRETES E COMISSÕES
  // ==========================================================

  void abrirFretesComissoes(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tela de Fretes e Comissões será criada na próxima etapa.',
        ),
      ),
    );
  }

  // ==========================================================
  // DIÁRIO DE BORDO
  // ==========================================================

  void abrirDiarioBordo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiarioBordoPage(
          motorista: nomeMotorista,
          caminhao: caminhao,
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controle de Transportes',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Histórico',
            onPressed: () =>
                abrirHistorico(context),
            icon: const Icon(
              Icons.history,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,

              children: [
                // ==================================================
                // DADOS DO MOTORISTA E CAMINHÃO
                // ==================================================

                Card(
                  child: Padding(
                    padding:
                    const EdgeInsets.all(18),

                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          child: Icon(
                            Icons.person,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                nomeMotorista,
                                style:
                                const TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                'Frota: ${caminhao.frota}',
                                style:
                                const TextStyle(
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                'Placa: ${caminhao.placa}',
                                style:
                                const TextStyle(
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                'Modelo: ${caminhao.modelo}',
                                style:
                                const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.local_shipping,
                          size: 35,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // RELATÓRIO DE DESPESAS
                // ==================================================

                BotaoMenu(
                  icone: Icons.receipt_long,
                  titulo:
                  'RELATÓRIO DE DESPESAS',
                  subtitulo:
                  'Registrar despesas e comprovantes',
                  onTap: () =>
                      abrirRelatorio(context),
                ),

                // ==================================================
                // ABASTECIMENTO
                // ==================================================

                BotaoMenu(
                  icone:
                  Icons.local_gas_station,
                  titulo:
                  'ABASTECIMENTO / CONTROLE DE MÁQUINAS',
                  subtitulo:
                  'Registrar abastecimentos',
                  onTap: () =>
                      abrirAbastecimento(context),
                ),

                // ==================================================
                // CONTROLE DE KM
                // ==================================================

                BotaoMenu(
                  icone: Icons.speed,
                  titulo: 'CONTROLE DE KM',
                  subtitulo:
                  'Informar KM inicial e final do mês',
                  onTap: () =>
                      abrirControleKm(context),
                ),

                // ==================================================
                // FRETES E COMISSÕES
                // ==================================================

                BotaoMenu(
                  icone: Icons.attach_money,
                  titulo:
                  'FRETES E COMISSÕES',
                  subtitulo:
                  'Registrar fretes e informações',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FretesComissoesPage(
                              motorista:
                              nomeMotorista,
                              caminhao:
                              caminhao,
                            ),
                      ),
                    );
                  },
                ),

                // ==================================================
                // DIÁRIO DE BORDO
                // ==================================================

                BotaoMenu(
                  icone: Icons.menu_book,
                  titulo:
                  'DIÁRIO DE BORDO',
                  subtitulo:
                  'Registrar as viagens',
                  onTap: () =>
                      abrirDiarioBordo(context),
                ),

                const SizedBox(height: 5),

                // ==================================================
                // HISTÓRICO
                // ==================================================

                OutlinedButton.icon(
                  onPressed: () =>
                      abrirHistorico(context),
                  icon: const Icon(
                    Icons.history,
                  ),
                  label: const Text(
                    'VER MEUS LANÇAMENTOS',
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

// ============================================================
// BOTÃO DO MENU
// ============================================================

class BotaoMenu extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const BotaoMenu({
    super.key,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 14),

      child: SizedBox(
        height: 82,

        child: ElevatedButton(
          onPressed: onTap,

          style: ElevatedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(14),
            ),
          ),

          child: Row(
            children: [
              Icon(
                icone,
                size: 34,
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
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
              ),
            ],
          ),
        ),
      ),
    );
  }
}