import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'selecao_caminhao.dart';

// ============================================================
// CONTROLE DE KM
// ============================================================

class ControleKmPage extends StatefulWidget {
  final String motorista;
  final Caminhao caminhao;

  const ControleKmPage({
    super.key,
    required this.motorista,
    required this.caminhao,
  });

  @override
  State<ControleKmPage> createState() => _ControleKmPageState();
}

class _ControleKmPageState extends State<ControleKmPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _kmController =
  TextEditingController();

  bool _carregando = true;
  bool _salvando = false;
  bool _fechandoMes = false;

  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  double? _kmInicialMes;
  double? _ultimoKm;

  bool _mesFechado = false;

  List<_RegistroKm> _registros = [];

  // ==========================================================
  // IDS
  // ==========================================================

  String get _idMes {
    return '${_anoSelecionado}_'
        '${_mesSelecionado.toString().padLeft(2, '0')}';
  }

  String get _documentoMes {
    return '${widget.caminhao.frota}_$_idMes';
  }

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _carregarControle();
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  // ==========================================================
  // CARREGAR CONTROLE
  // ==========================================================

  Future<void> _carregarControle() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final documento = await _firestore
          .collection('controle_km_mensal')
          .doc(_documentoMes)
          .get();

      double? kmInicial;
      double? ultimoKm;
      bool fechado = false;

      if (documento.exists) {
        final dados = documento.data();

        if (dados != null) {
          final valorInicial =
          _numero(dados['kmInicial']);

          if (valorInicial > 0) {
            kmInicial = valorInicial;
          }

          final valorUltimo =
          _numero(dados['ultimoKm']);

          if (valorUltimo > 0) {
            ultimoKm = valorUltimo;
          }

          fechado =
              dados['fechado'] == true;
        }
      }

      // ------------------------------------------------------
      // BUSCAR REGISTROS DIÁRIOS
      // ------------------------------------------------------

      final registrosSnapshot = await _firestore
          .collection('controle_km_diario')
          .where(
        'frota',
        isEqualTo: widget.caminhao.frota,
      )
          .where(
        'mes',
        isEqualTo: _mesSelecionado,
      )
          .where(
        'ano',
        isEqualTo: _anoSelecionado,
      )
          .get();

      final registros =
      registrosSnapshot.docs.map((doc) {
        final dados = doc.data();

        return _RegistroKm(
          id: doc.id,
          data: _converterData(
            dados['data'],
          ) ??
              DateTime(
                _anoSelecionado,
                _mesSelecionado,
                1,
              ),
          km: _numero(
            dados['km'],
          ),
        );
      }).toList();

      registros.sort(
            (a, b) => b.data.compareTo(a.data),
      );

      // ------------------------------------------------------
      // SE NÃO EXISTIR KM INICIAL,
      // TENTA PEGAR DO MÊS ANTERIOR
      // ------------------------------------------------------

      if (kmInicial == null) {
        final mesAnterior =
        DateTime(
          _anoSelecionado,
          _mesSelecionado - 1,
        );

        final idMesAnterior =
            '${mesAnterior.year}_'
            '${mesAnterior.month.toString().padLeft(2, '0')}';

        final documentoAnterior =
            '${widget.caminhao.frota}_$idMesAnterior';

        final anterior = await _firestore
            .collection('controle_km_mensal')
            .doc(documentoAnterior)
            .get();

        if (anterior.exists) {
          final dadosAnterior =
          anterior.data();

          if (dadosAnterior != null) {
            final kmFinalAnterior =
            _numero(
              dadosAnterior['ultimoKm'],
            );

            if (kmFinalAnterior > 0) {
              kmInicial =
                  kmFinalAnterior;
            }
          }
        }
      }

      // ------------------------------------------------------
      // SE AINDA NÃO EXISTIR KM INICIAL,
      // USA O PRIMEIRO REGISTRO DO MÊS
      // ------------------------------------------------------

      if (kmInicial == null &&
          registros.isNotEmpty) {
        final ordenados =
        [...registros];

        ordenados.sort(
              (a, b) =>
              a.data.compareTo(b.data),
        );

        kmInicial =
            ordenados.first.km;
      }

      // ------------------------------------------------------
      // SE EXISTIREM REGISTROS,
      // O ÚLTIMO KM É O MAIOR KM REGISTRADO.
      // ------------------------------------------------------

      if (registros.isNotEmpty) {
        final maiorKm =
        registros
            .map((e) => e.km)
            .reduce(
              (a, b) => a > b ? a : b,
        );

        ultimoKm =
            maiorKm;
      }

      if (!mounted) return;

      setState(() {
        _kmInicialMes = kmInicial;
        _ultimoKm = ultimoKm;
        _mesFechado = fechado;
        _registros = registros;

        _kmController.clear();
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao carregar controle de KM: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================================
  // REGISTRAR KM DO DIA
  // ==========================================================

  Future<void> _registrarKm() async {
    if (_mesFechado) {
      _mostrarMensagem(
        'Este mês já foi fechado.',
        erro: true,
      );
      return;
    }

    final texto =
    _kmController.text.trim();

    final km = _numero(texto);

    if (km <= 0) {
      _mostrarMensagem(
        'Informe um KM válido.',
        erro: true,
      );
      return;
    }

    // --------------------------------------------------------
    // NÃO PERMITIR KM MENOR QUE O ÚLTIMO
    // --------------------------------------------------------

    if (_ultimoKm != null &&
        km < _ultimoKm!) {
      _mostrarMensagem(
        'O KM informado não pode ser menor que o último KM registrado.',
        erro: true,
      );
      return;
    }

    // --------------------------------------------------------
    // PRIMEIRO REGISTRO DO MÊS
    // --------------------------------------------------------

    final kmInicial =
        _kmInicialMes ?? km;

    setState(() {
      _salvando = true;
    });

    try {
      final agora = DateTime.now();

      final idDia =
          '${widget.caminhao.frota}_'
          '${_idMes}_'
          '${agora.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('controle_km_diario')
          .doc(idDia)
          .set(
        {
          'frota':
          widget.caminhao.frota,
          'placa':
          widget.caminhao.placa,
          'modelo':
          widget.caminhao.modelo,
          'motorista':
          widget.motorista,
          'data': Timestamp.fromDate(
            DateTime(
              agora.year,
              agora.month,
              agora.day,
            ),
          ),
          'km': km,
          'mes': _mesSelecionado,
          'ano': _anoSelecionado,
          'atualizadoEm':
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // ------------------------------------------------------
      // SALVAR/ATUALIZAR RESUMO DO MÊS
      // ------------------------------------------------------

      await _firestore
          .collection('controle_km_mensal')
          .doc(_documentoMes)
          .set(
        {
          'frota':
          widget.caminhao.frota,
          'placa':
          widget.caminhao.placa,
          'modelo':
          widget.caminhao.modelo,
          'motorista':
          widget.motorista,
          'mes':
          _mesSelecionado,
          'ano':
          _anoSelecionado,
          'kmInicial':
          kmInicial,
          'ultimoKm':
          km,
          'kmRodado':
          km - kmInicial,
          'fechado':
          false,
          'atualizadoEm':
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      _kmController.clear();

      await _carregarControle();

      if (!mounted) return;

      _mostrarMensagem(
        'KM do dia salvo com sucesso.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Erro ao salvar KM: $e',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  // ==========================================================
  // FECHAR MÊS
  // ==========================================================

  Future<void> _confirmarFechamento() async {
    if (_mesFechado) {
      return;
    }

    if (_ultimoKm == null ||
        _ultimoKm! <= 0) {
      _mostrarMensagem(
        'Registre o KM do último dia antes de fechar o mês.',
        erro: true,
      );
      return;
    }

    final confirmado =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Fechar ${_nomeMes(_mesSelecionado)}/$_anoSelecionado?',
          ),
          content: Text(
            'O último KM registrado é '
                '${_formatarKm(_ultimoKm!)} km.\n\n'
                'Ao confirmar, este mês será encerrado e '
                'esse KM será automaticamente usado como '
                'KM inicial do próximo mês.\n\n'
                'O fechamento não poderá ser alterado pelo motorista.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'CANCELAR',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              icon: const Icon(
                Icons.lock,
              ),
              label: const Text(
                'CONFIRMAR E VIRAR MÊS',
              ),
            ),
          ],
        );
      },
    );

    if (confirmado != true) {
      return;
    }

    await _fecharMes();
  }

  // ==========================================================
  // FECHAR E CRIAR PRÓXIMO MÊS
  // ==========================================================

  Future<void> _fecharMes() async {
    setState(() {
      _fechandoMes = true;
    });

    try {
      final kmFinal = _ultimoKm!;

      // ------------------------------------------------------
      // FECHAR MÊS ATUAL
      // ------------------------------------------------------

      await _firestore
          .collection('controle_km_mensal')
          .doc(_documentoMes)
          .set(
        {
          'fechado': true,
          'kmFinal': kmFinal,
          'kmRodado':
          kmFinal -
              (_kmInicialMes ?? kmFinal),
          'fechadoEm':
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // ------------------------------------------------------
      // PRÓXIMO MÊS
      // ------------------------------------------------------

      final proximoMes =
      DateTime(
        _anoSelecionado,
        _mesSelecionado + 1,
      );

      final proximoId =
          '${proximoMes.year}_'
          '${proximoMes.month.toString().padLeft(2, '0')}';

      final proximoDocumento =
          '${widget.caminhao.frota}_$proximoId';

      final referenciaProximo =
      _firestore
          .collection(
        'controle_km_mensal',
      )
          .doc(proximoDocumento);

      final proximoExistente =
      await referenciaProximo.get();

      // ------------------------------------------------------
      // NÃO SOBRESCREVE SE JÁ EXISTIR
      // ------------------------------------------------------

      if (!proximoExistente.exists) {
        await referenciaProximo.set(
          {
            'frota':
            widget.caminhao.frota,
            'placa':
            widget.caminhao.placa,
            'modelo':
            widget.caminhao.modelo,
            'motorista':
            widget.motorista,
            'mes':
            proximoMes.month,
            'ano':
            proximoMes.year,
            'kmInicial':
            kmFinal,
            'ultimoKm':
            kmFinal,
            'kmRodado':
            0,
            'fechado':
            false,
            'criadoAutomaticamente':
            true,
            'criadoEm':
            FieldValue.serverTimestamp(),
          },
        );
      }

      if (!mounted) return;

      setState(() {
        _mesFechado = true;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Mês fechado com sucesso!',
            ),
            content: Text(
              '${_nomeMes(_mesSelecionado)}/$_anoSelecionado '
                  'foi encerrado.\n\n'
                  'O KM ${_formatarKm(kmFinal)} foi '
                  'transferido automaticamente para '
                  '${_nomeMes(proximoMes.month)}/${proximoMes.year} '
                  'como KM inicial.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'OK',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // ------------------------------------------------------
      // MUDAR AUTOMATICAMENTE PARA O PRÓXIMO MÊS
      // ------------------------------------------------------

      setState(() {
        _mesSelecionado =
            proximoMes.month;
        _anoSelecionado =
            proximoMes.year;
        _mesFechado = false;
        _kmInicialMes = kmFinal;
        _ultimoKm = kmFinal;
        _registros = [];
        _kmController.clear();
      });

      await _carregarControle();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Erro ao fechar mês: $e',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _fechandoMes = false;
        });
      }
    }
  }

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  void _mostrarMensagem(
      String mensagem, {
        bool erro = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
        erro ? Colors.red : Colors.green,
      ),
    );
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

    final texto = valor
        .toString()
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(texto) ?? 0;
  }

  // ==========================================================
  // DATA
  // ==========================================================

  DateTime? _converterData(
      dynamic valor) {
    if (valor is Timestamp) {
      return valor.toDate();
    }

    if (valor is DateTime) {
      return valor;
    }

    if (valor is String) {
      return DateTime.tryParse(valor);
    }

    return null;
  }

  // ==========================================================
  // FORMATAR KM
  // ==========================================================

  String _formatarKm(double valor) {
    return valor
        .toStringAsFixed(0);
  }

  // ==========================================================
  // KM RODADO
  // ==========================================================

  double get _kmRodado {
    if (_kmInicialMes == null ||
        _ultimoKm == null) {
      return 0;
    }

    final resultado =
        _ultimoKm! - _kmInicialMes!;

    return resultado >= 0
        ? resultado
        : 0;
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
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CONTROLE DE KM',
        ),
        centerTitle: true,
      ),
      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 650,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
              children: [
                // ==================================================
                // CAMINHÃO
                // ==================================================

                Card(
                  child: Padding(
                    padding:
                    const EdgeInsets
                        .all(18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          child: Icon(
                            Icons
                                .local_shipping,
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          child:
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                widget
                                    .caminhao
                                    .frota,
                                style:
                                const TextStyle(
                                  fontSize:
                                  20,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                'Placa: ${widget.caminhao.placa}',
                                style:
                                const TextStyle(
                                  fontSize:
                                  15,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                widget
                                    .caminhao
                                    .modelo,
                                style:
                                const TextStyle(
                                  fontSize:
                                  14,
                                  color:
                                  Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                // ==================================================
                // PERÍODO
                // ==================================================

                Card(
                  child: Padding(
                    padding:
                    const EdgeInsets
                        .all(18),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          '${_nomeMes(_mesSelecionado)} / $_anoSelecionado',
                          style:
                          const TextStyle(
                            fontSize: 20,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          _mesFechado
                              ? 'Mês fechado'
                              : 'Controle diário de quilometragem',
                          style:
                          TextStyle(
                            color: _mesFechado
                                ? Colors
                                .green
                                : Colors
                                .grey,
                            fontWeight:
                            _mesFechado
                                ? FontWeight
                                .bold
                                : FontWeight
                                .normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                // ==================================================
                // RESUMO
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: _cardResumo(
                        'KM INICIAL',
                        _kmInicialMes ==
                            null
                            ? '--'
                            : _formatarKm(
                          _kmInicialMes!,
                        ),
                        Icons
                            .play_arrow,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: _cardResumo(
                        'ÚLTIMO KM',
                        _ultimoKm ==
                            null
                            ? '--'
                            : _formatarKm(
                          _ultimoKm!,
                        ),
                        Icons.speed,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets
                      .all(18),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.blueGrey
                        .shade50,
                    borderRadius:
                    BorderRadius
                        .circular(14),
                    border:
                    Border.all(
                      color:
                      Colors.blueGrey
                          .shade100,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'KM RODADO NO MÊS',
                        style:
                        TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight
                              .bold,
                          color:
                          Colors.grey,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        '${_formatarKm(_kmRodado)} km',
                        style:
                        const TextStyle(
                          fontSize: 30,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // REGISTRAR KM
                // ==================================================

                if (!_mesFechado) ...[
                  TextField(
                    controller:
                    _kmController,
                    keyboardType:
                    const TextInputType
                        .numberWithOptions(
                      decimal: false,
                    ),
                    decoration:
                    const InputDecoration(
                      labelText:
                      'KM atual do veículo',
                      hintText:
                      'Ex.: 54280',
                      prefixIcon:
                      Icon(
                        Icons
                            .speed,
                      ),
                      suffixText:
                      'km',
                      border:
                      OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  SizedBox(
                    height: 54,
                    child:
                    ElevatedButton
                        .icon(
                      onPressed:
                      _salvando
                          ? null
                          : _registrarKm,
                      icon: _salvando
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                        ),
                      )
                          : const Icon(
                        Icons
                            .save,
                      ),
                      label: Text(
                        _salvando
                            ? 'SALVANDO...'
                            : 'SALVAR KM DO DIA',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (_ultimoKm != null)
                    SizedBox(
                      height: 54,
                      child:
                      OutlinedButton
                          .icon(
                        onPressed:
                        _fechandoMes
                            ? null
                            : _confirmarFechamento,
                        icon:
                        _fechandoMes
                            ? const SizedBox(
                          width:
                          20,
                          height:
                          20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                          ),
                        )
                            : const Icon(
                          Icons
                              .lock,
                        ),
                        label: Text(
                          _fechandoMes
                              ? 'FECHANDO...'
                              : 'FECHAR MÊS E VIRAR',
                        ),
                      ),
                    ),
                ],

                const SizedBox(
                  height: 25,
                ),

                // ==================================================
                // HISTÓRICO DIÁRIO
                // ==================================================

                const Text(
                  'HISTÓRICO DO MÊS',
                  style:
                  TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                if (_registros.isEmpty)
                  Container(
                    padding:
                    const EdgeInsets
                        .all(20),
                    decoration:
                    BoxDecoration(
                      borderRadius:
                      BorderRadius
                          .circular(
                        12,
                      ),
                      border:
                      Border.all(
                        color: Colors
                            .grey
                            .shade300,
                      ),
                    ),
                    child: const Text(
                      'Nenhum KM registrado neste mês.',
                      textAlign:
                      TextAlign.center,
                    ),
                  )
                else
                  ..._registros.map(
                        (registro) =>
                        _itemHistorico(
                          registro,
                        ),
                  ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // AVISO
                // ==================================================

                Container(
                  padding:
                  const EdgeInsets
                      .all(14),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.orange
                        .shade50,
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                    border:
                    Border.all(
                      color:
                      Colors.orange
                          .shade200,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Icon(
                        Icons
                            .info_outline,
                        color:
                        Colors.orange,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Informe o KM do veículo todos os dias. '
                              'No fechamento do mês, o último KM será '
                              'automaticamente utilizado como KM inicial '
                              'do próximo mês.',
                          style:
                          TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CARD RESUMO
  // ==========================================================

  Widget _cardResumo(
      String titulo,
      String valor,
      IconData icone,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            size: 25,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ITEM DO HISTÓRICO
  // ==========================================================

  Widget _itemHistorico(
      _RegistroKm registro) {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.speed,
          ),
        ),
        title: Text(
          _formatarData(
            registro.data,
          ),
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
        trailing: Text(
          '${_formatarKm(registro.km)} km',
          style: const TextStyle(
            fontSize: 17,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String _formatarData(
      DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
}

// ============================================================
// MODELO DO REGISTRO DIÁRIO
// ============================================================

class _RegistroKm {
  final String id;
  final DateTime data;
  final double km;

  _RegistroKm({
    required this.id,
    required this.data,
    required this.km,
  });
}