import 'package:flutter/material.dart';

import 'menu.dart';

// ============================================================
// MODELO DO CAMINHÃO
// ============================================================

class Caminhao {
  final String frota;
  final String placa;
  final String modelo;

  const Caminhao({
    required this.frota,
    required this.placa,
    required this.modelo,
  });
}

// ============================================================
// FROTA DA EMPRESA
// ============================================================

const List<Caminhao> frotaCaminhoes = [
  Caminhao(
    frota: 'CV18',
    placa: 'RBV4H22',
    modelo: 'BICAÇAMBA',
  ),
  Caminhao(
    frota: 'CV20',
    placa: 'RBV4F12',
    modelo: 'BICAÇAMBA',
  ),
  Caminhao(
    frota: 'CV21',
    placa: 'RBY1F12',
    modelo: 'BICAÇAMBA',
  ),
  Caminhao(
    frota: 'CV22',
    placa: 'RCI4I92',
    modelo: 'BICAÇAMBA',
  ),
  Caminhao(
    frota: 'CV23',
    placa: 'SDMOF18',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV24',
    placa: 'SDL6B18',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV25',
    placa: 'SDO9H28',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV26',
    placa: 'SDL4J38',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV27',
    placa: 'SDJ4D88',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV28',
    placa: 'SDJ4F88',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV29',
    placa: 'SDO4A98',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV30',
    placa: 'TFC3E31',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV31',
    placa: 'TFD0A71',
    modelo: '9 EIXOS',
  ),
  Caminhao(
    frota: 'CV32',
    placa: 'TGK2F21',
    modelo: 'BICAÇAMBA',
  ),
];

// ============================================================
// SELEÇÃO DO CAMINHÃO
// ============================================================

class SelecaoCaminhaoPage extends StatelessWidget {
  final String nomeMotorista;

  const SelecaoCaminhaoPage({
    super.key,
    required this.nomeMotorista,
  });

  void selecionarCaminhao(
      BuildContext context,
      Caminhao caminhao,
      ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MenuMotoristaPage(
          nomeMotorista: nomeMotorista,
          caminhao: caminhao,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SELECIONE O CAMINHÃO',
        ),
        centerTitle: true,
      ),

      backgroundColor: const Color(0xFFF5F6F8),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: frotaCaminhoes.length,
              itemBuilder: (context, index) {
                final caminhao = frotaCaminhoes[index];

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(14),
                    onTap: () => selecionarCaminhao(
                      context,
                      caminhao,
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.10),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_shipping,
                              size: 30,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  caminhao.frota,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  caminhao.placa,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                    FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  caminhao.modelo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                    Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.chevron_right,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}