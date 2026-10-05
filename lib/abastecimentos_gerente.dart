import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'selecao_caminhao.dart';

// ============================================================
// ABASTECIMENTOS - ÁREA DO GERENTE
// ============================================================

class AbastecimentosGerentePage extends StatefulWidget {
  const AbastecimentosGerentePage({super.key});

  @override
  State<AbastecimentosGerentePage> createState() =>
      _AbastecimentosGerentePageState();
}

class _AbastecimentosGerentePageState
    extends State<AbastecimentosGerentePage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  void _mostrarMensagem(
      String mensagem, {
        Color? cor,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: cor,
        ),
      );
  }

  // ==========================================================
  // FORMATAR MOEDA
  // ==========================================================

  String _formatarMoeda(dynamic valor) {
    if (valor == null) {
      return 'R\$ 0,00';
    }

    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(
      valor.toString().replaceAll(',', '.'),
    ) ??
        0;

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ==========================================================
  // ALTERAR PREÇO DO DIESEL
  // ==========================================================

  Future<void> _alterarPrecoLitro() async {
    // ========================================================
    // BUSCAR PREÇO ATUAL
    // ========================================================

    final documento = await _firestore
        .collection('configuracoes')
        .doc('abastecimento')
        .get();

    double? precoAtual;

    if (documento.exists) {
      final dados = documento.data();

      final valor = dados?['valorLitro'];

      if (valor is num) {
        precoAtual = valor.toDouble();
      }
    }

    final controller = TextEditingController(
      text: precoAtual == null
          ? ''
          : precoAtual
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );

    // ========================================================
    // DIÁLOGO
    // ========================================================

    final resultado = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Preço do diesel',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Valor do litro',
              hintText: 'Ex.: 6,29',
              prefixText: 'R\$ ',
              prefixIcon: Icon(
                Icons.local_gas_station,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'CANCELAR',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final texto = controller.text
                    .trim()
                    .replaceAll('.', '')
                    .replaceAll(',', '.');

                final valor =
                double.tryParse(texto);

                if (valor == null || valor <= 0) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  valor,
                );
              },
              icon: const Icon(
                Icons.save,
              ),
              label: const Text(
                'SALVAR',
              ),
            ),
          ],
        );
      },
    );

    // ========================================================
    // DESCARTAR CONTROLLER APÓS O DIÁLOGO
    // ========================================================

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (resultado == null) {
      return;
    }

    // ========================================================
    // SALVAR NOVO PREÇO
    // ========================================================

    try {
      final agora = FieldValue.serverTimestamp();

      // ------------------------------------------------------
      // PREÇO ATUAL
      // ------------------------------------------------------

      await _firestore
          .collection('configuracoes')
          .doc('abastecimento')
          .set(
        {
          'valorLitro': resultado,
          'atualizadoEm': agora,
        },
        SetOptions(merge: true),
      );

      // ------------------------------------------------------
      // HISTÓRICO DE PREÇOS
      // ------------------------------------------------------

      await _firestore
          .collection(
        'historico_precos_combustivel',
      )
          .add({
        'valorLitro': resultado,
        'alteradoEm': agora,
      });

      _mostrarMensagem(
        'Preço atualizado para '
            '${_formatarMoeda(resultado)} por litro.',
        cor: Colors.green,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _mostrarMensagem(
        'Erro ao atualizar preço: $e',
      );
    }
  }

  // ==========================================================
  // CARD DO PREÇO ATUAL
  // ==========================================================

  Widget _cardPrecoAtual() {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('configuracoes')
          .doc('abastecimento')
          .snapshots(),
      builder: (
          context,
          snapshot,
          ) {
        double? valor;

        if (snapshot.hasData &&
            snapshot.data!.exists) {
          final dados =
          snapshot.data!.data();

          final valorFirestore =
          dados?['valorLitro'];

          if (valorFirestore is num) {
            valor =
                valorFirestore.toDouble();
          }
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_gas_station,
                    color: Colors.green,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PREÇO ATUAL DO DIESEL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        valor == null
                            ? 'Ainda não definido'
                            : _formatarMoeda(valor),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                ElevatedButton.icon(
                  onPressed:
                  _alterarPrecoLitro,
                  icon: const Icon(
                    Icons.edit,
                  ),
                  label: const Text(
                    'ALTERAR',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // CARD DO CAMINHÃO
  // ==========================================================

  Widget _cardCaminhao(
      Caminhao caminhao,
      ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: const CircleAvatar(
          radius: 25,
          child: Icon(
            Icons.local_shipping,
          ),
        ),
        title: Text(
          caminhao.frota,
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${caminhao.placa} • ${caminhao.modelo}',
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AbastecimentosCaminhaoPage(
                    caminhao: caminhao,
                  ),
            ),
          );
        },
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
          'ABASTECIMENTOS',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 800,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  _cardPrecoAtual(),

                  const SizedBox(
                    height: 25,
                  ),

                  const Text(
                    'CAMINHÕES',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  ...frotaCaminhoes.map(
                    _cardCaminhao,
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

// ============================================================
// ABASTECIMENTOS DE UM CAMINHÃO
// ============================================================

class AbastecimentosCaminhaoPage
    extends StatefulWidget {
  final Caminhao caminhao;

  const AbastecimentosCaminhaoPage({
    super.key,
    required this.caminhao,
  });

  @override
  State<AbastecimentosCaminhaoPage>
  createState() =>
      _AbastecimentosCaminhaoPageState();
}

class _AbastecimentosCaminhaoPageState
    extends State<
        AbastecimentosCaminhaoPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // IDs que já estão sendo processados.
  final Set<String> _processando =
  <String>{};

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  void _mostrarMensagem(
      String mensagem, {
        Color? cor,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: cor,
        ),
      );
  }

  // ==========================================================
  // FORMATAR MOEDA
  // ==========================================================

  String _formatarMoeda(dynamic valor) {
    if (valor == null) {
      return 'R\$ 0,00';
    }

    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(
      valor.toString().replaceAll(',', '.'),
    ) ??
        0;

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ==========================================================
  // FORMATAR NÚMERO
  // ==========================================================

  String _formatarNumero(dynamic valor) {
    if (valor == null) {
      return '0';
    }

    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(
      valor.toString().replaceAll(',', '.'),
    ) ??
        0;

    if (numero == numero.roundToDouble()) {
      return numero.toInt().toString();
    }

    return numero
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  // ==========================================================
  // CONVERTER DATA
  // ==========================================================

  DateTime? _converterData(dynamic valor) {
    if (valor is Timestamp) {
      return valor.toDate();
    }

    if (valor is DateTime) {
      return valor;
    }

    if (valor is String) {
      final texto = valor.trim();

      // ------------------------------------------------------
      // DD/MM/AAAA
      // ------------------------------------------------------

      final partes = texto.split('/');

      if (partes.length == 3) {
        final dia =
        int.tryParse(partes[0]);

        final mes =
        int.tryParse(partes[1]);

        final ano =
        int.tryParse(partes[2]);

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
  // DATA SEM HORÁRIO
  // ==========================================================

  DateTime? _somenteData(
      DateTime? data,
      ) {
    if (data == null) {
      return null;
    }

    return DateTime(
      data.year,
      data.month,
      data.day,
    );
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String _formatarData(dynamic valor) {
    final data =
    _converterData(valor);

    if (data == null) {
      return '--/--/----';
    }

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  // ==========================================================
  // BUSCAR HISTÓRICO DE PREÇOS
  // ==========================================================

  Future<List<Map<String, dynamic>>>
  _buscarHistoricoPrecos() async {
    final snapshot = await _firestore
        .collection(
      'historico_precos_combustivel',
    )
        .get();

    final lista =
    <Map<String, dynamic>>[];

    for (final documento
    in snapshot.docs) {
      final dados =
      documento.data();

      final valor =
      dados['valorLitro'];

      final alteradoEm =
      dados['alteradoEm'];

      DateTime? dataAlteracao;

      if (alteradoEm is Timestamp) {
        dataAlteracao =
            alteradoEm.toDate();
      }

      if (valor is num &&
          dataAlteracao != null) {
        lista.add({
          'valorLitro':
          valor.toDouble(),
          'alteradoEm':
          dataAlteracao,
        });
      }
    }

    // Mais recente primeiro.
    lista.sort(
          (a, b) =>
          (b['alteradoEm'] as DateTime)
              .compareTo(
            a['alteradoEm'] as DateTime,
          ),
    );

    return lista;
  }

  // ==========================================================
  // ENCONTRAR PREÇO VIGENTE NA DATA
  // ==========================================================

  double? _precoVigente(
      DateTime? dataAbastecimento,
      List<Map<String, dynamic>> historico,
      ) {
    if (historico.isEmpty) {
      return null;
    }

    final dataLancamento =
    _somenteData(
      dataAbastecimento,
    );

    if (dataLancamento == null) {
      return null;
    }

    Map<String, dynamic>?
    encontrado;

    for (final item in historico) {
      final alteradoEm =
      item['alteradoEm']
      as DateTime;

      final dataPreco =
      _somenteData(alteradoEm);

      if (dataPreco == null) {
        continue;
      }

      // O preço vale a partir da data em que
      // foi cadastrado.
      if (!dataPreco.isAfter(
        dataLancamento,
      )) {
        encontrado = item;
        break;
      }
    }

    if (encontrado == null) {
      return null;
    }

    final valor =
    encontrado['valorLitro'];

    if (valor is num) {
      return valor.toDouble();
    }

    return null;
  }

  // ==========================================================
  // CALCULAR AUTOMATICAMENTE
  // ==========================================================

  Future<void> _calcularAutomaticamente(
      QueryDocumentSnapshot documento,
      Map<String, dynamic> dados,
      List<Map<String, dynamic>> historico,
      ) async {
    final id = documento.id;

    // Evita duas chamadas simultâneas.
    if (_processando.contains(id)) {
      return;
    }

    // Se já está calculado, não mexe.
    if (dados['valorLitro'] != null &&
        dados['valorTotal'] != null) {
      return;
    }

    final litros =
    dados['diesel'];

    if (litros == null) {
      return;
    }

    final litrosNumero =
    litros is num
        ? litros.toDouble()
        : double.tryParse(
      litros.toString()
          .replaceAll(',', '.'),
    ) ??
        0;

    if (litrosNumero <= 0) {
      return;
    }

    final data =
    _converterData(
      dados['data'],
    );

    final preco =
    _precoVigente(
      data,
      historico,
    );

    // Se ainda não existe preço correspondente
    // à data do abastecimento, não inventa valor.
    if (preco == null) {
      return;
    }

    final total =
        litrosNumero * preco;

    _processando.add(id);

    try {
      await documento.reference.update({
        'valorLitro': preco,
        'valorTotal': total,
        'valorCalculadoEm':
        FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Erro ao calcular abastecimento '
            '$id: $e',
      );
    } finally {
      _processando.remove(id);
    }
  }

  // ==========================================================
  // PROCESSAR TODOS OS ABASTECIMENTOS
  // ==========================================================

  Future<void> _processarPendentes(
      List<QueryDocumentSnapshot> documentos,
      List<Map<String, dynamic>> historico,
      ) async {
    if (historico.isEmpty) {
      return;
    }

    for (final documento in documentos) {
      final dados =
      documento.data()
      as Map<String, dynamic>;

      await _calcularAutomaticamente(
        documento,
        dados,
        historico,
      );
    }
  }

  // ==========================================================
  // LINHA DE INFORMAÇÃO
  // ==========================================================

  Widget _linhaInfo(
      String titulo,
      String valor,
      IconData icone,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Icon(
            icone,
            size: 19,
          ),
          const SizedBox(
            width: 9,
          ),
          Text(
            '$titulo: ',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              valor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RESUMO
  // ==========================================================

  Widget _resumo(
      String titulo,
      String valor,
      IconData icone,
      ) {
    return Column(
      children: [
        Icon(
          icone,
          size: 25,
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          titulo,
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          valor,
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CARD DO ABASTECIMENTO
  // ==========================================================

  Widget _cardAbastecimento(
      Map<String, dynamic> dados,
      ) {
    final litros =
    dados['diesel'];

    final arla =
    dados['arla'];

    final kmInicial =
    dados['kmInicial'];

    final kmFinal =
    dados['kmHor'];

    final motorista =
        dados['motorista']
            ?.toString() ??
            '';

    final valorLitro =
    dados['valorLitro'];

    final valorTotal =
    dados['valorTotal'];

    final kmInicialNumero =
        double.tryParse(
          kmInicial
              ?.toString()
              .replaceAll(',', '.') ??
              '',
        ) ??
            0;

    final kmFinalNumero =
        double.tryParse(
          kmFinal
              ?.toString()
              .replaceAll(',', '.') ??
              '',
        ) ??
            0;

    final kmRodado =
    kmFinalNumero >=
        kmInicialNumero
        ? kmFinalNumero -
        kmInicialNumero
        : 0;

    final calculado =
        valorLitro != null &&
            valorTotal != null;

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ==================================================
            // CABEÇALHO
            // ==================================================

            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.local_gas_station,
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
                        '${_formatarNumero(litros)} litros de diesel',
                        style:
                        const TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Data: ${_formatarData(dados['data'])}',
                      ),
                    ],
                  ),
                ),

                Icon(
                  calculado
                      ? Icons.check_circle
                      : Icons.pending,
                  color: calculado
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),

            const Divider(
              height: 25,
            ),

            // ==================================================
            // DADOS DO ABASTECIMENTO
            // ==================================================

            _linhaInfo(
              'Motorista',
              motorista.isEmpty
                  ? '-'
                  : motorista,
              Icons.person,
            ),

            _linhaInfo(
              'KM inicial',
              _formatarNumero(
                kmInicial,
              ),
              Icons.speed,
            ),

            _linhaInfo(
              'KM atual',
              _formatarNumero(
                kmFinal,
              ),
              Icons.speed,
            ),

            _linhaInfo(
              'KM rodado',
              _formatarNumero(
                kmRodado,
              ),
              Icons.route,
            ),

            _linhaInfo(
              'ARLA',
              _formatarNumero(
                arla,
              ),
              Icons.water_drop,
            ),

            const SizedBox(
              height: 8,
            ),

            // ==================================================
            // VALORES
            // ==================================================

            if (calculado)
              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(
                  14,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.green
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          'Valor por litro',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatarMoeda(
                            valorLitro,
                          ),
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style:
                          TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatarMoeda(
                            valorTotal,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(
                  14,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.orange
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      color:
                      Colors.orange,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        'Aguardando preço vigente para esta data.',
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
  Widget build(BuildContext context) {
    final query = _firestore
        .collection('abastecimentos')
        .where(
      'placa',
      isEqualTo:
      widget.caminhao.placa,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.caminhao.frota,
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar abastecimentos:\n'
                      '${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          final documentos =
          List<QueryDocumentSnapshot>.from(
            snapshot.data?.docs ?? [],
          );

          // ==================================================
          // ORDENAR POR DATA
          // ==================================================

          documentos.sort(
                (a, b) {
              final dadosA =
              a.data()
              as Map<String, dynamic>;

              final dadosB =
              b.data()
              as Map<String, dynamic>;

              final dataA =
                  _converterData(
                    dadosA['data'],
                  ) ??
                      DateTime(1900);

              final dataB =
                  _converterData(
                    dadosB['data'],
                  ) ??
                      DateTime(1900);

              return dataB.compareTo(dataA);
            },
          );

          // ==================================================
          // HISTÓRICO DE PREÇOS
          // ==================================================

          return FutureBuilder<
              List<Map<String, dynamic>>>(
            future:
            _buscarHistoricoPrecos(),
            builder: (
                context,
                historicoSnapshot,
                ) {
              final historico =
                  historicoSnapshot.data ??
                      [];

              // =================================================
              // CÁLCULO AUTOMÁTICO
              // =================================================

              if (historico.isNotEmpty) {
                WidgetsBinding.instance
                    .addPostFrameCallback(
                      (_) {
                    if (!mounted) return;

                    _processarPendentes(
                      documentos,
                      historico,
                    );
                  },
                );
              }

              // =================================================
              // TOTALIZADORES
              // =================================================

              double totalLitros = 0;
              double totalKmRodado = 0;
              double totalGasto = 0;

              for (final documento
              in documentos) {
                final dados =
                documento.data()
                as Map<String, dynamic>;

                final litros =
                dados['diesel'];

                if (litros is num) {
                  totalLitros +=
                      litros.toDouble();
                } else {
                  totalLitros +=
                      double.tryParse(
                        litros?.toString().replaceAll(',', '.') ?? '',
                      ) ?? 0;
                }

                final kmInicial =
                    double.tryParse(
                      dados['kmInicial']
                          ?.toString()
                          .replaceAll(',', '.') ??
                          '',
                    ) ??
                        0;

                final kmFinal =
                    double.tryParse(
                      dados['kmHor']
                          ?.toString()
                          .replaceAll(',', '.') ??
                          '',
                    ) ??
                        0;

                if (kmFinal >= kmInicial) {
                  totalKmRodado += kmFinal - kmInicial;
                }

                final total =
                dados['valorTotal'];

                if (total is num) {
                  totalGasto +=
                      total.toDouble();
                } else {
                  totalGasto +=
                      double.tryParse(
                        total?.toString().replaceAll(',', '.') ?? '',
                      ) ?? 0;
                }
              }

              final mediaKmPorLitro =
              totalLitros > 0
                  ? totalKmRodado / totalLitros
                  : 0;

              return Column(
                children: [
                  // =============================================
                  // CABEÇALHO DO CAMINHÃO
                  // =============================================

                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.all(
                      16,
                    ),
                    child: Card(
                      child: Padding(
                        padding:
                        const EdgeInsets.all(
                          18,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              widget.caminhao
                                  .frota,
                              style:
                              const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              '${widget.caminhao.placa} • ${widget.caminhao.modelo}',
                            ),

                            const Divider(
                              height: 25,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: _resumo(
                                    'QUANTIDADE',
                                    '${_formatarNumero(totalLitros)} L',
                                    Icons.local_gas_station,
                                  ),
                                ),

                                Expanded(
                                  child: _resumo(
                                    'KM RODADO',
                                    '${_formatarNumero(totalKmRodado)} km',
                                    Icons.route,
                                  ),
                                ),

                                Expanded(
                                  child: _resumo(
                                    'MÉDIA',
                                    '${_formatarNumero(mediaKmPorLitro)} km/L',
                                    Icons.speed,
                                  ),
                                ),

                                Expanded(
                                  child: _resumo(
                                    'TOTAL',
                                    _formatarMoeda(totalGasto),
                                    Icons.attach_money,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // =============================================
                  // LISTA
                  // =============================================

                  Expanded(
                    child: documentos.isEmpty
                        ? const Center(
                      child: Padding(
                        padding:
                        EdgeInsets.all(
                          30,
                        ),
                        child: Text(
                          'Nenhum abastecimento lançado para este caminhão.',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding:
                      const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        30,
                      ),
                      itemCount:
                      documentos.length,
                      itemBuilder:
                          (context, index) {
                        final dados =
                        documentos[index]
                            .data()
                        as Map<String,
                            dynamic>;

                        return _cardAbastecimento(
                          dados,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}