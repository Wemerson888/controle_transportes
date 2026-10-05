import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AbastecimentoPage extends StatefulWidget {
  final String? placaInicial;
  final String? modeloInicial;
  final String? motoristaInicial;

  const AbastecimentoPage({
    super.key,
    this.placaInicial,
    this.modeloInicial,
    this.motoristaInicial,
  });

  @override
  State<AbastecimentoPage> createState() =>
      _AbastecimentoPageState();
}

class _AbastecimentoPageState
    extends State<AbastecimentoPage> {
  final _formKey =
  GlobalKey<FormState>();

  final _placaController =
  TextEditingController();

  final _modeloController =
  TextEditingController();

  final _motoristaController =
  TextEditingController();

  final _kmInicialController =
  TextEditingController();

  final _dataController =
  TextEditingController();

  final _kmHorController =
  TextEditingController();

  final _dieselController =
  TextEditingController();

  final _arlaController =
  TextEditingController();

  final _empresaController =
  TextEditingController();

  final _observacaoController =
  TextEditingController();

  String? _combustivelSelecionado;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _carregando = false;

  DocumentSnapshot? _documentoEditando;

  // ==========================================================
  // MES ATUAL
  // ==========================================================

  String _mesAtual() {
    final agora = DateTime.now();

    return '${agora.year}_'
        '${agora.month.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // DOCUMENTO KM INICIAL
  // ==========================================================

  String _documentoKmInicial(
      String placa) {
    final placaNormalizada =
    placa.trim().toUpperCase();

    return '${placaNormalizada}_${_mesAtual()}';
  }

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _placaController.text =
        widget.placaInicial ?? '';

    _modeloController.text =
        widget.modeloInicial ?? '';

    // ========================================================
    // MOTORISTA VINDO DO LOGIN
    // ========================================================

    _motoristaController.text =
        widget.motoristaInicial ?? '';

    _dataController.text =
        _dataAtualFormatada();

    _carregarKmInicial();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _placaController.dispose();
    _modeloController.dispose();
    _motoristaController.dispose();
    _kmInicialController.dispose();
    _dataController.dispose();
    _kmHorController.dispose();
    _dieselController.dispose();
    _arlaController.dispose();
    _empresaController.dispose();
    _observacaoController.dispose();

    super.dispose();
  }

  // ==========================================================
  // DATA
  // ==========================================================

  String _dataAtualFormatada() {
    final agora = DateTime.now();

    return '${agora.day.toString().padLeft(2, '0')}/'
        '${agora.month.toString().padLeft(2, '0')}/'
        '${agora.year}';
  }

  // ==========================================================
  // SELECIONAR DATA
  // ==========================================================

  Future<void> _selecionarData() async {
    DateTime dataInicial =
    DateTime.now();

    final texto =
    _dataController.text.trim();

    if (texto.isNotEmpty) {
      final partes =
      texto.split('/');

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
          dataInicial =
              DateTime(
                ano,
                mes,
                dia,
              );
        }
      }
    }

    final selecionada =
    await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate:
      DateTime(2020),
      lastDate:
      DateTime(2100),
      locale:
      const Locale('pt', 'BR'),
    );

    if (selecionada == null) {
      return;
    }

    setState(() {
      _dataController.text =
      '${selecionada.day.toString().padLeft(2, '0')}/'
          '${selecionada.month.toString().padLeft(2, '0')}/'
          '${selecionada.year}';
    });
  }

  // ==========================================================
  // CARREGAR KM INICIAL
  // ==========================================================

  Future<void> _carregarKmInicial() async {
    final placa =
    _placaController.text
        .trim()
        .toUpperCase();

    if (placa.isEmpty) {
      return;
    }

    try {
      final documento =
      await _firestore
          .collection(
          'km_inicial_mensal')
          .doc(
        _documentoKmInicial(
            placa),
      )
          .get();

      if (!mounted) {
        return;
      }

      if (documento.exists) {
        final dados =
        documento.data();

        final km =
        dados?['kmInicial'];

        if (km != null) {
          setState(() {
            _kmInicialController
                .text =
                km.toString();
          });
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao carregar KM inicial: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // SALVAR KM INICIAL
  // ==========================================================

  Future<void> _salvarKmInicial() async {
    final placa =
    _placaController.text
        .trim()
        .toUpperCase();

    final valor =
    _kmInicialController.text
        .trim();

    if (placa.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe a placa do caminhão.',
          ),
        ),
      );
      return;
    }

    if (valor.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o KM inicial do mês.',
          ),
        ),
      );
      return;
    }

    final km =
    double.tryParse(
      valor.replaceAll(
        ',',
        '.',
      ),
    );

    if (km == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe um KM inicial válido.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await _firestore
          .collection(
          'km_inicial_mensal')
          .doc(
        _documentoKmInicial(
            placa),
      )
          .set({
        'placa': placa,
        'kmInicial': km,
        'mes': _mesAtual(),
        'atualizadoEm':
        FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'KM inicial do caminhão $placa salvo para este mês.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao salvar KM inicial: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ==========================================================
  // SALVAR ABASTECIMENTO
  // ==========================================================

  Future<void> _salvarOuAtualizar() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final placa =
    _placaController.text
        .trim()
        .toUpperCase();

    final motorista =
    _motoristaController.text
        .trim();

    final modelo =
    _modeloController.text
        .trim();

    final kmInicial =
    _kmInicialController.text
        .trim();

    if (motorista.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Motorista não identificado. Faça o login novamente.',
          ),
        ),
      );
      return;
    }

    if (kmInicial.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o KM inicial deste caminhão.',
          ),
        ),
      );
      return;
    }

    final diesel =
    _dieselController.text.trim();

    final arla =
    _arlaController.text.trim();

    if (_combustivelSelecionado ==
        'Diesel' ||
        _combustivelSelecionado ==
            'Diesel + Arla') {
      if (diesel.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Informe a quantidade de Diesel abastecida.',
            ),
          ),
        );
        return;
      }
    }

    if (_combustivelSelecionado ==
        'Arla' ||
        _combustivelSelecionado ==
            'Diesel + Arla') {
      if (arla.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Informe a quantidade de Arla abastecida.',
            ),
          ),
        );
        return;
      }
    }

    final dieselNumero =
    diesel.isEmpty
        ? 0
        : double.tryParse(
      diesel.replaceAll(
        ',',
        '.',
      ),
    );

    if (diesel.isNotEmpty &&
        dieselNumero == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe uma quantidade de Diesel válida.',
          ),
        ),
      );
      return;
    }

    final arlaNumero =
    arla.isEmpty
        ? 0
        : double.tryParse(
      arla.replaceAll(
        ',',
        '.',
      ),
    );

    if (arla.isNotEmpty &&
        arlaNumero == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe uma quantidade de Arla válida.',
          ),
        ),
      );
      return;
    }

    final kmInicialNumero =
    double.tryParse(
      kmInicial.replaceAll(
        ',',
        '.',
      ),
    );

    final kmHorTexto =
    _kmHorController.text.trim();

    final kmHorNumero =
    kmHorTexto.isEmpty
        ? null
        : double.tryParse(
      kmHorTexto.replaceAll(
        ',',
        '.',
      ),
    );

    if (kmHorTexto.isNotEmpty &&
        kmHorNumero == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe um KM/Horímetro válido.',
          ),
        ),
      );
      return;
    }

    if (kmInicialNumero == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe um KM inicial válido.',
          ),
        ),
      );
      return;
    }

    final dados = {
      'data':
      _dataController.text.trim(),

      // ======================================================
      // MOTORISTA VINCULADO AO LOGIN
      // ======================================================

      'motorista': motorista,

      'placa': placa,

      'modelo': modelo,

      'kmInicial':
      kmInicialNumero,

      'kmHor':
      kmHorNumero,

      'diesel':
      dieselNumero ?? 0,

      'arla':
      arlaNumero ?? 0,

      'combustivel':
      _combustivelSelecionado ?? '',

      'empresa':
      _empresaController.text
          .trim(),

      'observacao':
      _observacaoController.text
          .trim(),

      'mes':
      _mesAtual(),

    };

    setState(() {
      _carregando = true;
    });

    try {
      if (_documentoEditando != null) {
        await _firestore
            .collection(
            'abastecimentos')
            .doc(
          _documentoEditando!.id,
        )
            .update({
          ...dados,
          'atualizadoEm':
          FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore
            .collection(
            'abastecimentos')
            .add({
          ...dados,
          'criadoEm':
          FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) {
        return;
      }

      final estavaEditando =
          _documentoEditando != null;

      _documentoEditando = null;

      _limparFormulario();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            estavaEditando
                ? 'Abastecimento atualizado com sucesso!'
                : 'Abastecimento salvo com sucesso!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

    ScaffoldMessenger.of(context)
        .showSnackBar(
    SnackBar(
    content: Text(
    'Erro ao salvar abastecimento: $e',
    ),
    ),
    );
    } finally {
    if (mounted) {
    setState(() {
    _carregando = false;
    });
    }
    }
  }

  // ==========================================================
  // LIMPAR FORMULÁRIO
  // ==========================================================

  void _limparFormulario() {
    _dataController.text =
        _dataAtualFormatada();

    _kmHorController.clear();
    _dieselController.clear();
    _arlaController.clear();
    _empresaController.clear();
    _observacaoController.clear();

    setState(() {
      _combustivelSelecionado = null;
    });
  }

  // ==========================================================
  // EDITAR ABASTECIMENTO
  // ==========================================================

  Future<void> _editarAbastecimento(
      DocumentSnapshot documento) async {
    final dados =
    documento.data()
    as Map<String, dynamic>;

    _dataController.text =
        dados['data']?.toString() ??
            '';

    _placaController.text =
        dados['placa']?.toString() ??
            '';

    _modeloController.text =
        dados['modelo']?.toString() ??
            '';

    _motoristaController.text =
        dados['motorista']?.toString() ??
            widget.motoristaInicial ??
            '';

    final kmInicial =
    dados['kmInicial'];

    if (kmInicial != null) {
      _kmInicialController.text =
          _formatarNumero(kmInicial);
    }

    final kmHor =
    dados['kmHor'];

    _kmHorController.text =
    kmHor == null
        ? ''
        : _formatarNumero(kmHor);

    final diesel =
    dados['diesel'];

    _dieselController.text =
    diesel == null
        ? ''
        : _formatarNumero(diesel);

    final arla =
    dados['arla'];

    _arlaController.text =
    arla == null || arla == 0
        ? ''
        : _formatarNumero(arla);

    _empresaController.text =
        dados['empresa']?.toString() ??
            '';

    _observacaoController.text =
        dados['observacao']?.toString() ??
            '';

    final combustivel =
    dados['combustivel']
        ?.toString();

    setState(() {
      _combustivelSelecionado =
      combustivel == null ||
          combustivel.isEmpty
          ? null
          : combustivel;
    });

    _documentoEditando =
        documento;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Dados carregados para edição.',
        ),
      ),
    );
  }

  // ==========================================================
  // EXCLUIR ABASTECIMENTO
  // ==========================================================

  Future<void> _excluirAbastecimento(
      DocumentSnapshot documento) async {
    final confirmar =
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text(
              'Excluir abastecimento?',
            ),
            content: const Text(
              'Esse lançamento será removido permanentemente do Firebase.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      false,
                    ),
                child:
                const Text('CANCELAR'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      true,
                    ),
                child:
                const Text('EXCLUIR'),
              ),
            ],
          ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _firestore
          .collection(
          'abastecimentos')
          .doc(documento.id)
          .delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Abastecimento excluído com sucesso!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao excluir abastecimento: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // FORMATAR NÚMERO
  // ==========================================================

  String _formatarNumero(
      dynamic valor) {
    if (valor == null) {
      return '';
    }

    if (valor is num) {
      if (valor ==
          valor.roundToDouble()) {
        return valor
            .toInt()
            .toString();
      }

      return valor
          .toString()
          .replaceAll('.', ',');
    }

    return valor.toString();
  }

  // ==========================================================
  // DECORAÇÃO
  // ==========================================================

  InputDecoration _decoracao(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
      ),
    );
  }

  Widget _campo({
    required TextEditingController
    controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)?
    validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration:
      _decoracao(
        label,
        icon,
      ),
      validator: validator,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final placaAtual =
    _placaController.text
        .trim()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Abastecimento / Controle de Máquinas',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 700,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    // ==================================================
                    // VEÍCULO
                    // ==================================================

                    Card(
                      child: Padding(
                        padding:
                        const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VEÍCULO',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                                height: 14),

                            _campo(
                              controller:
                              _motoristaController,
                              label:
                              'Motorista',
                              icon:
                              Icons.person,
                              readOnly: true,
                            ),

                            const SizedBox(
                                height: 12),

                            _campo(
                              controller:
                              _placaController,
                              label:
                              'Placa',
                              icon:
                              Icons.local_shipping,
                              readOnly: true,
                              validator:
                                  (value) {
                                if (value ==
                                    null ||
                                    value
                                        .trim()
                                        .isEmpty) {
                                  return 'Informe a placa';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                                height: 12),

                            TextFormField(
                              controller:
                              _modeloController,
                              readOnly: true,
                              decoration:
                              _decoracao(
                                'Modelo',
                                Icons
                                    .directions_car,
                              ).copyWith(
                                suffixIcon:
                                const Icon(
                                  Icons
                                      .auto_awesome,
                                ),
                                hintText:
                                'Preenchido automaticamente',
                              ),
                            ),

                            const SizedBox(
                                height: 16),

                            const Text(
                              'KM INICIAL DO MÊS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                                height: 8),

                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Expanded(
                                  child:
                                  _campo(
                                    controller:
                                    _kmInicialController,
                                    label:
                                    'KM inicial',
                                    icon:
                                    Icons.speed,
                                    keyboardType:
                                    TextInputType
                                        .number,
                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Informe o KM inicial';
                                      }

                                      return null;
                                    },
                                  ),
                                ),

                                const SizedBox(
                                    width: 10),

                                SizedBox(
                                  height: 56,
                                  child:
                                  ElevatedButton(
                                    onPressed:
                                    _carregando
                                        ? null
                                        : _salvarKmInicial,
                                    child:
                                    const Text(
                                      'SALVAR',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 10),

                            StreamBuilder<
                                DocumentSnapshot>(
                              stream: _firestore
                                  .collection(
                                  'km_inicial_mensal')
                                  .doc(
                                _documentoKmInicial(
                                    placaAtual),
                              )
                                  .snapshots(),
                              builder:
                                  (context,
                                  snapshot) {
                                if (!snapshot
                                    .hasData ||
                                    !snapshot
                                        .data!
                                        .exists) {
                                  return const SizedBox
                                      .shrink();
                                }

                                final dados =
                                snapshot
                                    .data!
                                    .data()
                                as Map<
                                    String,
                                    dynamic>?;

                                final km =
                                dados?[
                                'kmInicial'];

                                if (km ==
                                    null) {
                                  return const SizedBox
                                      .shrink();
                                }

                                return Container(
                                  width:
                                  double.infinity,
                                  padding:
                                  const EdgeInsets
                                      .all(12),
                                  decoration:
                                  BoxDecoration(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      10,
                                    ),
                                    color: Colors
                                        .green
                                        .shade50,
                                  ),
                                  child:
                                  Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .check_circle,
                                        color: Colors
                                            .green
                                            .shade700,
                                      ),
                                      const SizedBox(
                                          width: 10),
                                      Expanded(
                                        child:
                                        Text(
                                          'KM inicial deste caminhão: '
                                              '${_formatarNumero(km)}',
                                          style:
                                          TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .bold,
                                            color: Colors
                                                .green
                                                .shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 16),

                    // ==================================================
                    // ABASTECIMENTO
                    // ==================================================

                    Card(
                      child: Padding(
                        padding:
                        const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                          children: [
                            const Text(
                              'ABASTECIMENTO',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                                height: 14),

                            // ==================================================
                            // DATA
                            // ==================================================

                            TextFormField(
                              controller:
                              _dataController,
                              readOnly: true,
                              onTap:
                              _selecionarData,
                              decoration:
                              _decoracao(
                                'Data',
                                Icons
                                    .calendar_month,
                              ).copyWith(
                                suffixIcon:
                                IconButton(
                                  onPressed:
                                  _selecionarData,
                                  icon:
                                  const Icon(
                                    Icons
                                        .calendar_today,
                                  ),
                                ),
                              ),
                              validator:
                                  (value) {
                                if (value ==
                                    null ||
                                    value
                                        .trim()
                                        .isEmpty) {
                                  return 'Informe a data';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                                height: 12),

                            _campo(
                              controller:
                              _kmHorController,
                              label:
                              'KM / Horímetro',
                              icon:
                              Icons.speed,
                              keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                                decimal: true,
                              ),
                              validator:
                                  (value) {
                                if (value ==
                                    null ||
                                    value
                                        .trim()
                                        .isEmpty) {
                                  return 'Informe o KM/Horímetro';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                                height: 12),

                            // ==================================================
                            // COMBUSTÍVEL
                            // ==================================================

                            DropdownButtonFormField<
                                String>(
                              initialValue:
                              _combustivelSelecionado,
                              decoration:
                              _decoracao(
                                'Combustível',
                                Icons
                                    .local_gas_station,
                              ),
                              items:
                              const [
                                DropdownMenuItem(
                                  value:
                                  'Diesel',
                                  child:
                                  Text(
                                    'Diesel',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value:
                                  'Arla',
                                  child:
                                  Text(
                                    'Arla',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value:
                                  'Diesel + Arla',
                                  child:
                                  Text(
                                    'Diesel + Arla',
                                  ),
                                ),
                              ],
                              onChanged:
                                  (value) {
                                setState(() {
                                  _combustivelSelecionado =
                                      value;

                                  if (value ==
                                      'Diesel') {
                                    _arlaController
                                        .clear();
                                  }

                                  if (value ==
                                      'Arla') {
                                    _dieselController
                                        .clear();
                                  }

                                  if (value ==
                                      null) {
                                    _dieselController
                                        .clear();
                                    _arlaController
                                        .clear();
                                  }
                                });
                              },
                              validator:
                                  (value) {
                                if (value ==
                                    null ||
                                    value
                                        .isEmpty) {
                                  return 'Selecione o combustível';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                                height: 12),

                            // ==================================================
                            // DIESEL
                            // ==================================================

                            if (_combustivelSelecionado ==
                                'Diesel' ||
                                _combustivelSelecionado ==
                                    'Diesel + Arla')
                              Padding(
                                padding:
                                const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: _campo(
                                  controller:
                                  _dieselController,
                                  label:
                                  'Diesel (litros)',
                                  icon:
                                  Icons
                                      .local_gas_station,
                                  keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator:
                                      (value) {
                                    if (_combustivelSelecionado ==
                                        'Diesel' ||
                                        _combustivelSelecionado ==
                                            'Diesel + Arla') {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Obrigatório';
                                      }
                                    }

                                    return null;
                                  },
                                ),
                              ),

                            // ==================================================
                            // ARLA
                            // ==================================================

                            if (_combustivelSelecionado ==
                                'Arla' ||
                                _combustivelSelecionado ==
                                    'Diesel + Arla')
                              Padding(
                                padding:
                                const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: _campo(
                                  controller:
                                  _arlaController,
                                  label:
                                  'Arla (litros)',
                                  icon:
                                  Icons
                                      .water_drop,
                                  keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator:
                                      (value) {
                                    if (_combustivelSelecionado ==
                                        'Arla' ||
                                        _combustivelSelecionado ==
                                            'Diesel + Arla') {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Obrigatório';
                                      }
                                    }

                                    return null;
                                  },
                                ),
                              ),

                            _campo(
                              controller:
                              _empresaController,
                              label:
                              'Empresa',
                              icon:
                              Icons.business,
                              validator:
                                  (value) {
                                if (value ==
                                    null ||
                                    value
                                        .trim()
                                        .isEmpty) {
                                  return 'Informe a empresa';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                                height: 12),

                            TextFormField(
                              controller:
                              _observacaoController,
                              maxLines: 3,
                              decoration:
                              _decoracao(
                                'Observação (opcional)',
                                Icons.notes,
                              ),
                            ),

                            const SizedBox(
                                height: 18),

                            // ==================================================
                            // SALVAR
                            // ==================================================

                            SizedBox(
                              height: 56,
                              child:
                              ElevatedButton
                                  .icon(
                                onPressed:
                                _carregando
                                    ? null
                                    : _salvarOuAtualizar,
                                icon:
                                _carregando
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
                                  Icons.save,
                                ),
                                label:
                                Text(
                                  _documentoEditando ==
                                      null
                                      ? 'SALVAR ABASTECIMENTO'
                                      : 'SALVAR ALTERAÇÕES',
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    16,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // HISTÓRICO
                    // ==================================================

                    const SizedBox(
                        height: 24),

                    const Text(
                      'ABASTECIMENTOS LANÇADOS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                        height: 10),

                    StreamBuilder<
                        QuerySnapshot>(
                      stream: _firestore
                          .collection(
                          'abastecimentos')
                          .where(
                        'placa',
                        isEqualTo:
                        placaAtual,
                      )
                          .snapshots(),
                      builder:
                          (context,
                          snapshot) {
                        if (snapshot
                            .connectionState ==
                            ConnectionState
                                .waiting) {
                          return const Center(
                            child:
                            Padding(
                              padding:
                              EdgeInsets
                                  .all(25),
                              child:
                              CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot
                            .hasError) {
                          return Card(
                            child:
                            Padding(
                              padding:
                              const EdgeInsets
                                  .all(16),
                              child: Text(
                                'Erro ao carregar abastecimentos: '
                                    '${snapshot.error}',
                              ),
                            ),
                          );
                        }

                        final documentos =
                            snapshot.data
                                ?.docs ??
                                [];

                        if (documentos
                            .isEmpty) {
                          return const Card(
                            child:
                            Padding(
                              padding:
                              EdgeInsets
                                  .all(20),
                              child:
                              Text(
                                'Nenhum abastecimento lançado para este caminhão.',
                                textAlign:
                                TextAlign
                                    .center,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children:
                          documentos.map(
                                (documento) {
                              final item =
                              documento.data()
                              as Map<
                                  String,
                                  dynamic>;

                              return Card(
                                margin:
                                const EdgeInsets
                                    .only(
                                  bottom: 10,
                                ),
                                child:
                                ListTile(
                                  leading:
                                  const CircleAvatar(
                                    child:
                                    Icon(
                                      Icons
                                          .local_gas_station,
                                    ),
                                  ),
                                  title:
                                  Text(
                                    '${item['data'] ?? ''} — '
                                        '${item['placa'] ?? ''}',
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                  subtitle:
                                  Text(
                                    'Motorista: '
                                        '${item['motorista'] ?? ''}\n'
                                        'KM inicial: '
                                        '${_formatarNumero(item['kmInicial'])}\n'
                                        'KM/Hor: '
                                        '${_formatarNumero(item['kmHor'])}\n'
                                        'Combustível: '
                                        '${item['combustivel'] ?? ''}\n'
                                        'Diesel: '
                                        '${_formatarNumero(item['diesel'])} L   '
                                        'Arla: '
                                        '${_formatarNumero(item['arla'])} L\n'
                                        'Empresa: '
                                        '${item['empresa'] ?? ''}',
                                  ),
                                  isThreeLine:
                                  true,
                                  trailing:
                                  PopupMenuButton<
                                      String>(
                                    onSelected:
                                        (value) {
                                      if (value ==
                                          'editar') {
                                        _editarAbastecimento(
                                            documento);
                                      } else if (value ==
                                          'excluir') {
                                        _excluirAbastecimento(
                                            documento);
                                      }
                                    },
                                    itemBuilder:
                                        (context) =>
                                    const [
                                      PopupMenuItem(
                                        value:
                                        'editar',
                                        child:
                                        Text(
                                          'Editar',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value:
                                        'excluir',
                                        child:
                                        Text(
                                          'Excluir',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}