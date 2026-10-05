import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'selecao_caminhao.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState
    extends State<DashboardPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  late int _mesSelecionado;
  late int _anoSelecionado;

  Future<_DadosDashboard>? _dadosFuture;

  @override
  void initState() {
    super.initState();

    final agora = DateTime.now();

    _mesSelecionado = agora.month;
    _anoSelecionado = agora.year;

    _atualizar();
  }

  // ==========================================================
  // ATUALIZAR
  // ==========================================================

  void _atualizar() {
    _dadosFuture = _buscarDados();
  }

  // ==========================================================
  // TROCAR MÊS
  // ==========================================================

  void _trocarMes(int? valor) {
    if (valor == null) return;

    setState(() {
      _mesSelecionado = valor;
      _atualizar();
    });
  }

  // ==========================================================
  // TROCAR ANO
  // ==========================================================

  void _trocarAno(int? valor) {
    if (valor == null) return;

    setState(() {
      _anoSelecionado = valor;
      _atualizar();
    });
  }

  // ==========================================================
  // BUSCAR DADOS
  // ==========================================================

  Future<_DadosDashboard> _buscarDados() async {
    final resultado =
    _DadosDashboard.criar(
      frotaCaminhoes,
    );

    // ========================================================
    // MOTORISTAS ATIVOS
    // ========================================================

    final motoristasSnapshot =
    await _firestore
        .collection('usuarios')
        .where(
      'tipo',
      isEqualTo: 'motorista',
    )
        .where(
      'ativo',
      isEqualTo: true,
    )
        .get();

    resultado.motoristasAtivos =
        motoristasSnapshot.docs.length;

    // ========================================================
    // FRETES
    // ========================================================

    final fretesSnapshot =
    await _firestore
        .collection('fretes')
        .get();

    for (final documento
    in fretesSnapshot.docs) {
      final dados =
      documento.data();

      final data =
      _converterData(
        dados['data'],
      );

      if (data == null) {
        continue;
      }

      if (data.year !=
          _anoSelecionado ||
          data.month !=
              _mesSelecionado) {
        continue;
      }

      final frota =
      dados['frota']
          ?.toString()
          .trim();

      if (frota == null ||
          frota.isEmpty) {
        continue;
      }

      final dadosFrota =
      resultado.frotas[frota];

      if (dadosFrota == null) {
        continue;
      }

      final peso =
      _numero(
        dados['peso'],
      );

      dadosFrota.fretes++;

      dadosFrota.toneladas +=
          peso;

      resultado.totalFretes++;

      resultado.totalToneladas +=
          peso;
    }

    // ========================================================
    // KM MENSAL
    // ========================================================

    final kmSnapshot =
    await _firestore
        .collection(
      'controle_km_mensal',
    )
        .get();

    for (final documento
    in kmSnapshot.docs) {
      final dados =
      documento.data();

      final mes =
      _numeroInteiro(
        dados['mes'],
      );

      final ano =
      _numeroInteiro(
        dados['ano'],
      );

      if (mes !=
          _mesSelecionado ||
          ano !=
              _anoSelecionado) {
        continue;
      }

      final frota =
      dados['frota']
          ?.toString()
          .trim();

      if (frota == null ||
          frota.isEmpty) {
        continue;
      }

      final dadosFrota =
      resultado.frotas[frota];

      if (dadosFrota == null) {
        continue;
      }

      double kmRodado =
      _numero(
        dados['kmRodado'],
      );

      // ------------------------------------------------------
      // SE KM RODADO ESTIVER ZERADO,
      // CALCULA PELO INICIAL E ÚLTIMO KM
      // ------------------------------------------------------

      if (kmRodado <= 0) {
        final kmInicial =
        _numero(
          dados['kmInicial'],
        );

        final ultimoKm =
        _numero(
          dados['ultimoKm'],
        );

        if (ultimoKm >= kmInicial &&
            kmInicial > 0) {
          kmRodado =
              ultimoKm - kmInicial;
        }
      }

      // Evita somar novamente caso exista
      // mais de um documento da mesma frota.
      dadosFrota.kmRodado =
          kmRodado;
    }

    // ========================================================
    // ABASTECIMENTOS
    // ========================================================

    final abastecimentosSnapshot =
    await _firestore
        .collection(
      'abastecimentos',
    )
        .get();

    for (final documento
    in abastecimentosSnapshot.docs) {
      final dados =
      documento.data();

      final data =
      _converterData(
        dados['data'],
      );

      if (data == null) {
        continue;
      }

      if (data.year !=
          _anoSelecionado ||
          data.month !=
              _mesSelecionado) {
        continue;
      }

      resultado
          .totalAbastecimentos++;

      final placa =
      dados['placa']
          ?.toString()
          .trim()
          .toUpperCase();

      if (placa == null ||
          placa.isEmpty) {
        continue;
      }

      for (final frota
      in resultado.frotas.values) {
        if (frota.placa
            .toUpperCase() ==
            placa) {
          frota.abastecimentos++;
          break;
        }
      }
    }

    return resultado;
  }

  // ==========================================================
  // NÚMERO
  // ==========================================================

  double _numero(dynamic valor) {
    if (valor == null) {
      return 0;
    }

    if (valor is num) {
      return valor.toDouble();
    }

    final texto =
    valor
        .toString()
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(texto) ??
        0;
  }

  int _numeroInteiro(dynamic valor) {
    return _numero(valor).round();
  }

  // ==========================================================
  // DATA
  // ==========================================================

  DateTime? _converterData(
      dynamic valor,
      ) {
    if (valor == null) {
      return null;
    }

    if (valor is Timestamp) {
      return valor.toDate();
    }

    if (valor is DateTime) {
      return valor;
    }

    if (valor is String) {
      final texto =
      valor.trim();

      // DD/MM/AAAA

      final partes =
      texto.split('/');

      if (partes.length == 3) {
        final dia =
        int.tryParse(
          partes[0],
        );

        final mes =
        int.tryParse(
          partes[1],
        );

        final ano =
        int.tryParse(
          partes[2],
        );

        if (dia != null &&
            mes != null &&
            ano != null) {
          return DateTime(
            ano,
            mes,
            dia,
          );
        }
      }

      return DateTime.tryParse(
        texto,
      );
    }

    return null;
  }

  // ==========================================================
  // NOME DO MÊS
  // ==========================================================

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return meses[mes - 1];
  }

  // ==========================================================
  // FORMATA NÚMERO
  // ==========================================================

  String _formatarNumero(
      double valor, {
        int casas = 2,
      }) {
    return valor
        .toStringAsFixed(casas)
        .replaceAll('.', ',');
  }

  // ==========================================================
  // CARD INDICADOR
  // ==========================================================

  Widget _cardIndicador({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Card(
      elevation: 2,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              child:
              Icon(icone),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color:
                      Colors.grey,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    valor,
                    style:
                    const TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CARD DA FROTA
  // ==========================================================

  Widget _cardFrota(
      _DadosFrotaDashboard dados,
      ) {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 23,
                  child: Icon(
                    Icons.local_shipping,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        dados.frota,
                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '${dados.placa} • ${dados.modelo}',
                        style:
                        const TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 15,
            ),

            Row(
              children: [
                _itemFrota(
                  Icons.local_shipping,
                  'Fretes',
                  dados.fretes
                      .toString(),
                ),
                _itemFrota(
                  Icons.scale,
                  'Toneladas',
                  _formatarNumero(
                    dados.toneladas,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                _itemFrota(
                  Icons.speed,
                  'KM Rodado',
                  _formatarNumero(
                    dados.kmRodado,
                    casas: 0,
                  ),
                ),
                _itemFrota(
                  Icons.local_gas_station,
                  'Abastecimentos',
                  dados.abastecimentos
                      .toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ITEM DA FROTA
  // ==========================================================

  Widget _itemFrota(
      IconData icone,
      String titulo,
      String valor,
      ) {
    return Expanded(
      child: Container(
        margin:
        const EdgeInsets.all(4),
        padding:
        const EdgeInsets.all(10),
        decoration:
        BoxDecoration(
          color:
          Colors.grey.shade100,
          borderRadius:
          BorderRadius.circular(
            10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icone,
              size: 20,
              color:
              Colors.grey.shade700,
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 10,
                      color:
                      Colors.grey,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    valor,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text(
          'DASHBOARD',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip:
            'Atualizar',
            onPressed: () {
              setState(() {
                _atualizar();
              });
            },
            icon:
            const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // FILTROS
            // ==================================================

            Card(
              margin:
              const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                10,
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                      DropdownButtonFormField<int>(
                        initialValue:
                        _mesSelecionado,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Mês',
                          border:
                          OutlineInputBorder(),
                        ),
                        items:
                        List.generate(
                          12,
                              (index) {
                            final mes =
                                index + 1;

                            return DropdownMenuItem<
                                int>(
                              value: mes,
                              child:
                              Text(
                                _nomeMes(
                                  mes,
                                ),
                              ),
                            );
                          },
                        ),
                        onChanged:
                        _trocarMes,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                      DropdownButtonFormField<int>(
                        initialValue:
                        _anoSelecionado,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Ano',
                          border:
                          OutlineInputBorder(),
                        ),
                        items:
                        List.generate(
                          8,
                              (index) {
                            final ano =
                                DateTime.now()
                                    .year -
                                    2 +
                                    index;

                            return DropdownMenuItem<
                                int>(
                              value: ano,
                              child:
                              Text(
                                ano.toString(),
                              ),
                            );
                          },
                        ),
                        onChanged:
                        _trocarAno,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // CONTEÚDO
            // ==================================================

            Expanded(
              child:
              FutureBuilder<
                  _DadosDashboard>(
                future:
                _dadosFuture,
                builder:
                    (
                    context,
                    snapshot,
                    ) {
                  if (snapshot
                      .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                      CircularProgressIndicator(),
                    );
                  }

                  if (snapshot
                      .hasError) {
                    return Center(
                      child: Padding(
                        padding:
                        const EdgeInsets
                            .all(
                          25,
                        ),
                        child:
                        Column(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons
                                  .error_outline,
                              size: 60,
                              color:
                              Colors.red,
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            const Text(
                              'Erro ao carregar o Dashboard.',
                              textAlign:
                              TextAlign
                                  .center,
                              style:
                              TextStyle(
                                fontSize:
                                18,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              '${snapshot.error}',
                              textAlign:
                              TextAlign
                                  .center,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            ElevatedButton
                                .icon(
                              onPressed:
                                  () {
                                setState(
                                      () {
                                    _atualizar();
                                  },
                                );
                              },
                              icon:
                              const Icon(
                                Icons.refresh,
                              ),
                              label:
                              const Text(
                                'TENTAR NOVAMENTE',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final dados =
                      snapshot.data;

                  if (dados == null) {
                    return const Center(
                      child:
                      Text(
                        'Nenhum dado encontrado.',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh:
                        () async {
                      setState(() {
                        _atualizar();
                      });

                      await _dadosFuture;
                    },
                    child:
                    ListView(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        16,
                        8,
                        16,
                        30,
                      ),
                      children: [
                        // ========================================
                        // PERÍODO
                        // ========================================

                        Padding(
                          padding:
                          const EdgeInsets
                              .only(
                            bottom: 15,
                          ),
                          child:
                          Text(
                            '${_nomeMes(_mesSelecionado)} '
                                'de $_anoSelecionado',
                            style:
                            const TextStyle(
                              fontSize:
                              20,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ),

                        // ========================================
                        // INDICADORES
                        // ========================================

                        Row(
                          children: [
                            Expanded(
                              child:
                              _cardIndicador(
                                icone:
                                Icons.local_shipping,
                                titulo:
                                'Caminhões',
                                valor:
                                dados.totalCaminhoes.toString(),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                              _cardIndicador(
                                icone:
                                Icons.people,
                                titulo:
                                'Motoristas ativos',
                                valor:
                                dados.motoristasAtivos.toString(),
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Expanded(
                              child:
                              _cardIndicador(
                                icone:
                                Icons.local_shipping,
                                titulo:
                                'Fretes',
                                valor:
                                dados.totalFretes.toString(),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                              _cardIndicador(
                                icone:
                                Icons.scale,
                                titulo:
                                'Toneladas',
                                valor:
                                _formatarNumero(
                                  dados.totalToneladas,
                                ),
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Expanded(
                              child:
                              _cardIndicador(
                                icone:
                                Icons.speed,
                                titulo:
                                'KM rodados',
                                valor:
                                _formatarNumero(
                                  dados.totalKm,
                                  casas:
                                  0,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                              _cardIndicador(
                                icone:
                                Icons.local_gas_station,
                                titulo:
                                'Abastecimentos',
                                valor:
                                dados.totalAbastecimentos.toString(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // ========================================
                        // TÍTULO FROTAS
                        // ========================================

                        const Text(
                          'RESUMO POR FROTA',
                          style:
                          TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        ...dados.frotas.values
                            .map(
                              (frota) =>
                              _cardFrota(
                                frota,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DADOS DE UMA FROTA
// ============================================================

class _DadosFrotaDashboard {
  final String frota;
  final String placa;
  final String modelo;

  int fretes = 0;
  double toneladas = 0;
  double kmRodado = 0;
  int abastecimentos = 0;

  _DadosFrotaDashboard({
    required this.frota,
    required this.placa,
    required this.modelo,
  });
}

// ============================================================
// DADOS DO DASHBOARD
// ============================================================

class _DadosDashboard {
  int totalCaminhoes = 0;
  int motoristasAtivos = 0;

  int totalFretes = 0;
  double totalToneladas = 0;
  double totalKm = 0;

  int totalAbastecimentos = 0;

  final Map<
      String,
      _DadosFrotaDashboard> frotas = {};

  static _DadosDashboard criar(
      List<Caminhao> caminhoes,
      ) {
    final resultado =
    _DadosDashboard();

    resultado.totalCaminhoes =
        caminhoes.length;

    for (final caminhao
    in caminhoes) {
      resultado.frotas[
      caminhao.frota] =
          _DadosFrotaDashboard(
            frota:
            caminhao.frota,
            placa:
            caminhao.placa,
            modelo:
            caminhao.modelo,
          );
    }

    return resultado;
  }
}