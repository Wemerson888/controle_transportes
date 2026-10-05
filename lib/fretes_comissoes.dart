import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'selecao_caminhao.dart';

class FretesComissoesPage extends StatefulWidget {
  final String motorista;
  final Caminhao caminhao;

  const FretesComissoesPage({
    super.key,
    required this.motorista,
    required this.caminhao,
  });

  @override
  State<FretesComissoesPage> createState() =>
      _FretesComissoesPageState();
}

class _FretesComissoesPageState
    extends State<FretesComissoesPage> {
  final _formKey = GlobalKey<FormState>();

  final origemController = TextEditingController();
  final notaFiscalController = TextEditingController();
  final pesoController = TextEditingController();
  final materialOutroController = TextEditingController();
  final observacaoController = TextEditingController();

  DateTime? dataFrete;

  String? materialSelecionado;

  // ==========================================================
  // CLIENTE SELECIONADO
  // ==========================================================

  String? clienteSelecionadoId;
  String? clienteSelecionadoNome;

  bool salvando = false;

  // ==========================================================
  // MATERIAIS
  // ==========================================================

  final List<String> materiais = const [
    'Calcário Dolomítico',
    'Calcário Calcítico',
    'Brita 00',
    'Brita 01',
    'Pó de Brita',
    'Pó de Brita com Imp. BY PASS',
    'Pedra Marroada',
    'OUTRO',
  ];

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    origemController.dispose();
    notaFiscalController.dispose();
    pesoController.dispose();
    materialOutroController.dispose();
    observacaoController.dispose();

    super.dispose();
  }

  // ==========================================================
  // SELECIONAR DATA
  // ==========================================================

  Future<void> selecionarData() async {
    final hoje = DateTime.now();

    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: dataFrete ?? hoje,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'SELECIONE A DATA DO FRETE',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );

    if (dataSelecionada != null) {
      setState(() {
        dataFrete = dataSelecionada;
      });
    }
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String formatarData(DateTime? data) {
    if (data == null) {
      return 'Selecionar data';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  String formatarTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return '-';
    }

    return formatarData(timestamp.toDate());
  }

  // ==========================================================
  // MATERIAL FINAL
  // ==========================================================

  String get materialFinal {
    if (materialSelecionado == 'OUTRO') {
      return materialOutroController.text.trim();
    }

    return materialSelecionado ?? '';
  }

  // ==========================================================
  // SELEÇÃO DE CLIENTE
  // ==========================================================

  Widget campoCliente() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('clientes_motoristas')
            .where(
          'ativo',
          isEqualTo: true,
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const InputDecorator(
              decoration: InputDecoration(
                labelText: 'Cliente',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Carregando clientes...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Cliente',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              child: Text(
                'Erro ao carregar clientes.',
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
              ),
            );
          }

          final clientes = List<
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>.from(
            snapshot.data?.docs ?? [],
          );

          // ======================================================
          // ORDENAR POR NOME
          // ======================================================

          clientes.sort((a, b) {
            final nomeA =
                a.data()['nome']
                    ?.toString()
                    .toLowerCase() ??
                    '';

            final nomeB =
                b.data()['nome']
                    ?.toString()
                    .toLowerCase() ??
                    '';

            return nomeA.compareTo(nomeB);
          });

          if (clientes.isEmpty) {
            return const InputDecorator(
              decoration: InputDecoration(
                labelText: 'Cliente',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              child: Text(
                'Nenhum cliente disponível.',
              ),
            );
          }

          // ======================================================
          // GARANTIR QUE O CLIENTE SELECIONADO AINDA EXISTE
          // ======================================================

          final idsDisponiveis =
          clientes.map((e) => e.id).toSet();

          if (clienteSelecionadoId != null &&
              !idsDisponiveis
                  .contains(clienteSelecionadoId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              setState(() {
                clienteSelecionadoId = null;
                clienteSelecionadoNome = null;
              });
            });
          }

          return DropdownButtonFormField<String>(
            initialValue: clienteSelecionadoId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cliente',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
            items: clientes.map((cliente) {
              final dados = cliente.data();

              final nome =
                  dados['nome']
                      ?.toString() ??
                      'Cliente';

              return DropdownMenuItem<String>(
                value: cliente.id,
                child: Text(
                  nome,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (valor) {
              if (valor == null) {
                return;
              }

              final cliente =
              clientes.firstWhere(
                    (item) => item.id == valor,
              );

              final dados = cliente.data();

              setState(() {
                clienteSelecionadoId =
                    cliente.id;

                clienteSelecionadoNome =
                    dados['nome']
                        ?.toString();
              });
            },
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Selecione o cliente';
              }

              return null;
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // SALVAR FRETE
  // ==========================================================

  Future<void> salvarFrete() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ========================================================
    // VALIDAR DATA
    // ========================================================

    if (dataFrete == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione a data do frete.',
          ),
        ),
      );

      return;
    }

    // ========================================================
    // VALIDAR MATERIAL
    // ========================================================

    if (materialSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione o material.',
          ),
        ),
      );

      return;
    }

    // ========================================================
    // VALIDAR OUTRO MATERIAL
    // ========================================================

    if (materialSelecionado == 'OUTRO' &&
        materialOutroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digite qual é o material.',
          ),
        ),
      );

      return;
    }

    // ========================================================
    // VALIDAR CLIENTE
    // ========================================================

    if (clienteSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione o cliente.',
          ),
        ),
      );

      return;
    }

    // ========================================================
    // CONVERTER PESO
    // ========================================================

    final pesoTexto = pesoController.text
        .trim()
        .replaceAll(',', '.');

    final peso = double.tryParse(pesoTexto);

    if (peso == null || peso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe um peso válido.',
          ),
        ),
      );

      return;
    }

    // ========================================================
    // INICIAR SALVAMENTO
    // ========================================================

    setState(() {
      salvando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('fretes')
          .add({
        // ====================================================
        // MOTORISTA
        // ====================================================

        'motorista': widget.motorista,

        // ====================================================
        // CAMINHÃO
        // ====================================================

        'frota': widget.caminhao.frota,
        'placa': widget.caminhao.placa,
        'modelo': widget.caminhao.modelo,

        // ====================================================
        // DATA
        // ====================================================

        'data': Timestamp.fromDate(dataFrete!),

        // ====================================================
        // CLIENTE
        // ====================================================

        'clienteId': clienteSelecionadoId,
        'cliente': clienteSelecionadoNome,

        // ====================================================
        // DADOS DO FRETE
        // ====================================================

        'origem': origemController.text.trim(),
        'notaFiscal': notaFiscalController.text.trim(),

        // ====================================================
        // MATERIAL
        // ====================================================

        'material': materialFinal,

        // ====================================================
        // PESO
        // ====================================================

        'peso': peso,

        // ====================================================
        // OBSERVAÇÃO
        // ====================================================

        'observacao':
        observacaoController.text.trim(),

        // ====================================================
        // DATA DE CRIAÇÃO
        // ====================================================

        'criadoEm':
        FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Frete salvo com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      limparFormulario();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao salvar o frete: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
        });
      }
    }
  }

  // ==========================================================
  // LIMPAR FORMULÁRIO
  // ==========================================================

  void limparFormulario() {
    origemController.clear();
    notaFiscalController.clear();
    pesoController.clear();
    materialOutroController.clear();
    observacaoController.clear();

    setState(() {
      dataFrete = null;
      materialSelecionado = null;

      clienteSelecionadoId = null;
      clienteSelecionadoNome = null;
    });
  }

  // ==========================================================
  // CAMPO DE TEXTO
  // ==========================================================

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
    bool obrigatorio = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon)
              : null,
          border: const OutlineInputBorder(),
        ),
        validator: obrigatorio
            ? (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return 'Informe $label';
          }

          return null;
        }
            : null,
      ),
    );
  }

  // ==========================================================
  // CAMPO DATA
  // ==========================================================

  Widget campoData() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: InkWell(
        onTap: selecionarData,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Data',
            prefixIcon: Icon(
              Icons.calendar_month,
            ),
            border: OutlineInputBorder(),
          ),
          child: Text(
            formatarData(dataFrete),
            style: TextStyle(
              fontSize: 16,
              color: dataFrete == null
                  ? Colors.grey.shade600
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CAMPO MATERIAL
  // ==========================================================

  Widget campoMaterial() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: DropdownButtonFormField<String>(
            initialValue: materialSelecionado,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Material',
              prefixIcon: Icon(
                Icons.inventory_2,
              ),
              border: OutlineInputBorder(),
            ),
            items: materiais.map(
                  (material) {
                return DropdownMenuItem<String>(
                  value: material,
                  child: Text(material),
                );
              },
            ).toList(),
            onChanged: (valor) {
              setState(() {
                materialSelecionado = valor;

                if (valor != 'OUTRO') {
                  materialOutroController.clear();
                }
              });
            },
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Selecione o material';
              }

              return null;
            },
          ),
        ),

        // ======================================================
        // OUTRO MATERIAL
        // ======================================================

        if (materialSelecionado == 'OUTRO')
          campoTexto(
            label: 'Qual material?',
            controller: materialOutroController,
            icon: Icons.edit,
            hint: 'Digite o nome do material',
          ),
      ],
    );
  }

  // ==========================================================
  // IDENTIFICAÇÃO DO CAMINHÃO
  // ==========================================================

  Widget identificacaoCaminhao() {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              child: Icon(
                Icons.local_shipping,
                size: 32,
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
                    widget.motorista,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Frota: ${widget.caminhao.frota}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Placa: ${widget.caminhao.placa}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Modelo: ${widget.caminhao.modelo}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
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
  // ABRIR HISTÓRICO
  // ==========================================================

  void abrirHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoricoFretesPage(
          motorista: widget.motorista,
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
          'FRETES E COMISSÕES',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Histórico de fretes',
            onPressed: abrirHistorico,
            icon: const Icon(
              Icons.history,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    identificacaoCaminhao(),

                    const Text(
                      'DADOS DO FRETE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    campoData(),

                    campoTexto(
                      label: 'Origem',
                      controller: origemController,
                      icon: Icons.trip_origin,
                    ),

                    campoCliente(),

                    campoTexto(
                      label: 'Nota Fiscal',
                      controller:
                      notaFiscalController,
                      icon: Icons.receipt_long,
                      keyboardType:
                      TextInputType.text,
                    ),

                    campoMaterial(),

                    campoTexto(
                      label: 'Peso (toneladas)',
                      controller: pesoController,
                      icon: Icons.scale,
                      keyboardType:
                      const TextInputType
                          .numberWithOptions(
                        decimal: true,
                      ),
                      hint: 'Ex.: 43,54',
                    ),

                    campoTexto(
                      label: 'Observação',
                      controller:
                      observacaoController,
                      icon: Icons.notes,
                      maxLines: 4,
                      obrigatorio: false,
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                        salvando
                            ? null
                            : salvarFrete,
                        icon: salvando
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons.save,
                        ),
                        label: Text(
                          salvando
                              ? 'SALVANDO...'
                              : 'SALVAR FRETE',
                          style:
                          const TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed:
                      abrirHistorico,
                      icon: const Icon(
                        Icons.history,
                      ),
                      label: const Text(
                        'VER HISTÓRICO DE FRETES',
                      ),
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

// ============================================================
// HISTÓRICO DE FRETES
// ============================================================

class HistoricoFretesPage extends StatelessWidget {
  final String motorista;

  const HistoricoFretesPage({
    super.key,
    required this.motorista,
  });

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String formatarData(
      Timestamp? timestamp,
      ) {
    if (timestamp == null) {
      return '-';
    }

    final data = timestamp.toDate();

    final dia =
    data.day.toString().padLeft(2, '0');

    final mes =
    data.month.toString().padLeft(2, '0');

    final ano =
    data.year.toString();

    return '$dia/$mes/$ano';
  }

  // ==========================================================
  // FORMATAR PESO
  // ==========================================================

  String formatarPeso(dynamic valor) {
    if (valor == null) {
      return '0,00 t';
    }

    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(
      valor.toString(),
    ) ??
        0;

    return '${numero.toStringAsFixed(2).replaceAll('.', ',')} t';
  }

  // ==========================================================
  // EDITAR FRETE
  // ==========================================================

  Future<void> editarFrete(
      BuildContext context,
      String id,
      Map<String, dynamic> dados,
      ) async {
    final origemController =
    TextEditingController(
      text:
      dados['origem']?.toString() ?? '',
    );

    final notaFiscalController =
    TextEditingController(
      text:
      dados['notaFiscal']?.toString() ?? '',
    );

    final pesoController =
    TextEditingController(
      text:
      dados['peso']?.toString() ?? '',
    );

    final observacaoController =
    TextEditingController(
      text:
      dados['observacao']?.toString() ?? '',
    );

    // ========================================================
    // CLIENTE EXISTENTE
    // ========================================================

    String? clienteSelecionadoId =
    dados['clienteId']?.toString();

    String? clienteSelecionadoNome =
    dados['cliente']?.toString();

    final materialExistente =
        dados['material']?.toString() ?? '';

    String? materialSelecionado;

    String materialOutro = '';

    if (materiaisParaEdicao
        .contains(materialExistente)) {
      materialSelecionado =
          materialExistente;
    } else if (materialExistente
        .isNotEmpty) {
      materialSelecionado = 'OUTRO';
      materialOutro =
          materialExistente;
    }

    final materialOutroController =
    TextEditingController(
      text: materialOutro,
    );

    DateTime? dataFrete;

    if (dados['data'] is Timestamp) {
      dataFrete =
          (dados['data'] as Timestamp)
              .toDate();
    }

    bool salvandoEdicao = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            Future<void> escolherData() async {
              final data =
              await showDatePicker(
                context: context,
                initialDate:
                dataFrete ??
                    DateTime.now(),
                firstDate:
                DateTime(2020),
                lastDate:
                DateTime(2100),
                locale:
                const Locale(
                  'pt',
                  'BR',
                ),
                helpText:
                'DATA DO FRETE',
                cancelText:
                'CANCELAR',
                confirmText:
                'CONFIRMAR',
              );

              if (data != null) {
                setDialogState(() {
                  dataFrete = data;
                });
              }
            }

            String textoData(
                DateTime? data,
                ) {
              if (data == null) {
                return 'Selecionar data';
              }

              final dia = data.day
                  .toString()
                  .padLeft(
                2,
                '0',
              );

              final mes = data.month
                  .toString()
                  .padLeft(
                2,
                '0',
              );

              return '$dia/$mes/${data.year}';
            }

            Future<void> salvarEdicao() async {
              final origem =
              origemController
                  .text
                  .trim();

              final notaFiscal =
              notaFiscalController
                  .text
                  .trim();

              final observacao =
              observacaoController
                  .text
                  .trim();

              if (origem.isEmpty ||
                  notaFiscal.isEmpty ||
                  dataFrete ==
                      null ||
                  materialSelecionado ==
                      null ||
                  clienteSelecionadoId ==
                      null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Preencha todos os campos obrigatórios.',
                    ),
                  ),
                );

                return;
              }

              if (materialSelecionado ==
                  'OUTRO' &&
                  materialOutroController
                      .text
                      .trim()
                      .isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Digite qual é o material.',
                    ),
                  ),
                );

                return;
              }

              final pesoTexto =
              pesoController
                  .text
                  .trim()
                  .replaceAll(
                ',',
                '.',
              );

              final peso =
              double.tryParse(
                pesoTexto,
              );

              if (peso == null ||
                  peso <= 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Informe um peso válido.',
                    ),
                  ),
                );

                return;
              }

              final materialEditado =
              materialSelecionado ==
                  'OUTRO'
                  ? materialOutroController
                  .text
                  .trim()
                  : materialSelecionado!;

              setDialogState(() {
                salvandoEdicao =
                true;
              });

              try {
                await FirebaseFirestore
                    .instance
                    .collection('fretes')
                    .doc(id)
                    .update({
                  'data':
                  Timestamp.fromDate(
                    dataFrete!,
                  ),

                  // ==================================================
                  // NOVA ESTRUTURA: CLIENTE
                  // ==================================================

                  'clienteId':
                  clienteSelecionadoId,

                  'cliente':
                  clienteSelecionadoNome,

                  // ==================================================
                  // REMOVER CAMPOS ANTIGOS DE LOJA
                  // ==================================================

                  'lojaId':
                  FieldValue.delete(),

                  'loja':
                  FieldValue.delete(),

                  // ==================================================
                  // DADOS DO FRETE
                  // ==================================================

                  'origem': origem,

                  'notaFiscal':
                  notaFiscal,

                  'material':
                  materialEditado,

                  'peso': peso,

                  'observacao':
                  observacao,

                  'editadoEm':
                  FieldValue
                      .serverTimestamp(),
                });

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(
                  context,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Frete atualizado com sucesso!',
                    ),
                    backgroundColor:
                    Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) {
                  return;
                }

                setDialogState(() {
                  salvandoEdicao =
                  false;
                });

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Erro ao editar o frete: $e',
                    ),
                    backgroundColor:
                    Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text(
                'EDITAR FRETE',
              ),
              content:
              SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      // ==================================================
                      // DATA
                      // ==================================================

                      InkWell(
                        onTap:
                        escolherData,
                        child:
                        InputDecorator(
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Data',
                            prefixIcon:
                            Icon(
                              Icons
                                  .calendar_month,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          child:
                          Text(
                            textoData(
                                dataFrete),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      // ==================================================
                      // CLIENTE
                      // ==================================================

                      StreamBuilder<
                          QuerySnapshot<
                              Map<String,
                                  dynamic>>>(
                        stream:
                        FirebaseFirestore
                            .instance
                            .collection(
                          'clientes_motoristas',
                        )
                            .where(
                          'ativo',
                          isEqualTo:
                          true,
                        )
                            .snapshots(),
                        builder:
                            (
                            context,
                            snapshot,
                            ) {
                          if (snapshot
                              .connectionState ==
                              ConnectionState
                                  .waiting) {
                            return const InputDecorator(
                              decoration:
                              InputDecoration(
                                labelText:
                                'Cliente',
                                prefixIcon:
                                Icon(
                                  Icons
                                      .business,
                                ),
                                border:
                                OutlineInputBorder(),
                              ),
                              child:
                              Text(
                                'Carregando clientes...',
                              ),
                            );
                          }

                          if (snapshot
                              .hasError) {
                            return InputDecorator(
                              decoration:
                              const InputDecoration(
                                labelText:
                                'Cliente',
                                prefixIcon:
                                Icon(
                                  Icons
                                      .business,
                                ),
                                border:
                                OutlineInputBorder(),
                              ),
                              child:
                              Text(
                                'Erro ao carregar clientes.',
                                style:
                                TextStyle(
                                  color:
                                  Colors.red,
                                ),
                              ),
                            );
                          }

                          final clientes =
                          List<
                              QueryDocumentSnapshot<
                                  Map<String,
                                      dynamic>>>.from(
                            snapshot.data
                                ?.docs ??
                                [],
                          );

                          clientes.sort(
                                (a, b) {
                              final dadosA =
                              a.data();

                              final dadosB =
                              b.data();

                              final nomeA =
                                  dadosA[
                                  'nome']
                                      ?.toString()
                                      .toLowerCase() ??
                                      '';

                              final nomeB =
                                  dadosB[
                                  'nome']
                                      ?.toString()
                                      .toLowerCase() ??
                                      '';

                              return nomeA
                                  .compareTo(
                                nomeB,
                              );
                            },
                          );

                          if (clientes.isEmpty) {
                            return const InputDecorator(
                              decoration:
                              InputDecoration(
                                labelText:
                                'Cliente',
                                prefixIcon:
                                Icon(
                                  Icons
                                      .business,
                                ),
                                border:
                                OutlineInputBorder(),
                              ),
                              child:
                              Text(
                                'Nenhum cliente disponível.',
                              ),
                            );
                          }

                          // ==================================================
                          // VERIFICAR CLIENTE ATUAL
                          // ==================================================

                          final clienteAtualExiste =
                              clienteSelecionadoId !=
                                  null &&
                                  clientes.any(
                                        (cliente) =>
                                    cliente.id ==
                                        clienteSelecionadoId,
                                  );

                          // ==================================================
                          // CASO O FRETE ANTIGO TENHA CLIENTE INATIVO
                          // ==================================================

                          if (!clienteAtualExiste &&
                              clienteSelecionadoId !=
                                  null) {
                            return Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,
                              children: [
                                DropdownButtonFormField<
                                    String>(
                                  initialValue:
                                  null,
                                  isExpanded:
                                  true,
                                  decoration:
                                  const InputDecoration(
                                    labelText:
                                    'Cliente',
                                    prefixIcon:
                                    Icon(
                                      Icons
                                          .business,
                                    ),
                                    border:
                                    OutlineInputBorder(),
                                  ),
                                  items:
                                  clientes
                                      .map(
                                        (
                                        cliente,
                                        ) {
                                      final dados =
                                      cliente
                                          .data();

                                      return DropdownMenuItem<
                                          String>(
                                        value:
                                        cliente.id,
                                        child:
                                        Text(
                                          dados[
                                          'nome']
                                              ?.toString() ??
                                              'Cliente',
                                          overflow:
                                          TextOverflow
                                              .ellipsis,
                                        ),
                                      );
                                    },
                                  ).toList(),
                                  onChanged:
                                      (valor) {
                                    if (valor ==
                                        null) {
                                      return;
                                    }

                                    final cliente =
                                    clientes
                                        .firstWhere(
                                          (
                                          item,
                                          ) =>
                                      item.id ==
                                          valor,
                                    );

                                    final dados =
                                    cliente
                                        .data();

                                    setDialogState(
                                          () {
                                        clienteSelecionadoId =
                                            cliente.id;

                                        clienteSelecionadoNome =
                                            dados[
                                            'nome']
                                                ?.toString();
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(
                                    height: 8),
                                Text(
                                  'O cliente deste lançamento está inativo. Selecione um cliente ativo para alterar.',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    12,
                                    color:
                                    Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            );
                          }

                          return DropdownButtonFormField<
                              String>(
                            initialValue:
                            clienteSelecionadoId,
                            isExpanded:
                            true,
                            decoration:
                            const InputDecoration(
                              labelText:
                              'Cliente',
                              prefixIcon:
                              Icon(
                                Icons
                                    .business,
                              ),
                              border:
                              OutlineInputBorder(),
                            ),
                            items:
                            clientes
                                .map(
                                  (
                                  cliente,
                                  ) {
                                final dados =
                                cliente
                                    .data();

                                return DropdownMenuItem<
                                    String>(
                                  value:
                                  cliente.id,
                                  child:
                                  Text(
                                    dados[
                                    'nome']
                                        ?.toString() ??
                                        'Cliente',
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged:
                                (valor) {
                              if (valor ==
                                  null) {
                                return;
                              }

                              final cliente =
                              clientes
                                  .firstWhere(
                                    (
                                    item,
                                    ) =>
                                item.id ==
                                    valor,
                              );

                              final dados =
                              cliente
                                  .data();

                              setDialogState(
                                    () {
                                  clienteSelecionadoId =
                                      cliente.id;

                                  clienteSelecionadoNome =
                                      dados[
                                      'nome']
                                          ?.toString();
                                },
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(
                          height: 12),

                      // ==================================================
                      // ORIGEM
                      // ==================================================

                      TextFormField(
                        controller:
                        origemController,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Origem',
                          prefixIcon:
                          Icon(
                            Icons
                                .trip_origin,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      // ==================================================
                      // NOTA FISCAL
                      // ==================================================

                      TextFormField(
                        controller:
                        notaFiscalController,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Nota Fiscal',
                          prefixIcon:
                          Icon(
                            Icons
                                .receipt_long,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      // ==================================================
                      // MATERIAL
                      // ==================================================

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                        materialSelecionado,
                        isExpanded:
                        true,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Material',
                          prefixIcon:
                          Icon(
                            Icons
                                .inventory_2,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                        items:
                        materiaisParaEdicao
                            .map(
                              (
                              material,
                              ) {
                            return DropdownMenuItem<
                                String>(
                              value:
                              material,
                              child:
                              Text(
                                material,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (valor) {
                          setDialogState(
                                () {
                              materialSelecionado =
                                  valor;

                              if (valor !=
                                  'OUTRO') {
                                materialOutroController
                                    .clear();
                              }
                            },
                          );
                        },
                      ),

                      if (materialSelecionado ==
                          'OUTRO') ...[
                        const SizedBox(
                            height: 12),
                        TextFormField(
                          controller:
                          materialOutroController,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Qual material?',
                            prefixIcon:
                            Icon(
                              Icons.edit,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                        ),
                      ],

                      const SizedBox(
                          height: 12),

                      // ==================================================
                      // PESO
                      // ==================================================

                      TextFormField(
                        controller:
                        pesoController,
                        keyboardType:
                        const TextInputType
                            .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Peso (toneladas)',
                          prefixIcon:
                          Icon(
                            Icons.scale,
                          ),
                          hintText:
                          'Ex.: 43,54',
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      // ==================================================
                      // OBSERVAÇÃO
                      // ==================================================

                      TextFormField(
                        controller:
                        observacaoController,
                        maxLines: 4,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Observação',
                          prefixIcon:
                          Icon(
                            Icons.notes,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                  salvandoEdicao
                      ? null
                      : () =>
                      Navigator.pop(
                        context,
                      ),
                  child:
                  const Text(
                    'CANCELAR',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                  salvandoEdicao
                      ? null
                      : salvarEdicao,
                  icon: salvandoEdicao
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.save,
                  ),
                  label: Text(
                    salvandoEdicao
                        ? 'SALVANDO...'
                        : 'SALVAR ALTERAÇÃO',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    origemController.dispose();
    notaFiscalController.dispose();
    pesoController.dispose();
    observacaoController.dispose();
    materialOutroController.dispose();
  }

  // ==========================================================
  // LISTA DE MATERIAIS PARA EDIÇÃO
  // ==========================================================

  static const List<String> materiaisParaEdicao = [
    'Calcário Dolomítico',
    'Calcário Calcítico',
    'Brita 00',
    'Brita 01',
    'Pó de Brita',
    'Pó de Brita com Imp. BY PASS',
    'Pedra Marroada',
    'OUTRO',
  ];

  // ==========================================================
  // BUILD HISTÓRICO
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HISTÓRICO DE FRETES',
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('fretes')
            .where(
          'motorista',
          isEqualTo: motorista,
        )
            .orderBy(
          'data',
          descending: true,
        )
            .snapshots(),
        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(20),
                child: Text(
                  'Erro ao carregar histórico:\n'
                      '${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final documentos =
              snapshot.data?.docs ?? [];

          if (documentos.isEmpty) {
            return const Center(
              child: Padding(
                padding:
                EdgeInsets.all(30),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .local_shipping_outlined,
                      size: 70,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Nenhum frete lançado.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding:
            const EdgeInsets.all(16),
            itemCount:
            documentos.length,
            itemBuilder: (
                context,
                index,
                ) {
              final documento =
              documentos[index];

              final dados =
              documento.data();

              final id =
                  documento.id;

              final material =
                  dados['material']
                      ?.toString() ??
                      '-';

              final origem =
                  dados['origem']
                      ?.toString() ??
                      '-';

              final cliente =
                  dados['cliente']
                      ?.toString() ??
                      '-';

              final notaFiscal =
                  dados['notaFiscal']
                      ?.toString() ??
                      '-';

              final frota =
                  dados['frota']
                      ?.toString() ??
                      '-';

              final placa =
                  dados['placa']
                      ?.toString() ??
                      '-';

              final modelo =
                  dados['modelo']
                      ?.toString() ??
                      '-';

              final peso =
              dados['peso'];

              final data =
              dados['data']
              is Timestamp
                  ? dados['data']
              as Timestamp
                  : null;

              return Card(
                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),
                child: ExpansionTile(
                  leading:
                  const CircleAvatar(
                    child: Icon(
                      Icons
                          .local_shipping,
                    ),
                  ),
                  title: Text(
                    '$frota - $placa',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${formatarData(data)} • '
                        '$material • '
                        '${formatarPeso(peso)}',
                  ),
                  trailing:
                  IconButton(
                    tooltip: 'Editar',
                    icon:
                    const Icon(
                      Icons.edit,
                    ),
                    onPressed: () {
                      editarFrete(
                        context,
                        id,
                        dados,
                      );
                    },
                  ),
                  childrenPadding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    0,
                    20,
                    18,
                  ),
                  children: [
                    _linhaHistorico(
                      'Motorista',
                      motorista,
                    ),
                    _linhaHistorico(
                      'Data',
                      formatarData(
                        data,
                      ),
                    ),
                    _linhaHistorico(
                      'Frota',
                      frota,
                    ),
                    _linhaHistorico(
                      'Placa',
                      placa,
                    ),
                    _linhaHistorico(
                      'Modelo',
                      modelo,
                    ),
                    _linhaHistorico(
                      'Origem',
                      origem,
                    ),
                    _linhaHistorico(
                      'Cliente',
                      cliente,
                    ),
                    _linhaHistorico(
                      'Nota Fiscal',
                      notaFiscal,
                    ),
                    _linhaHistorico(
                      'Material',
                      material,
                    ),
                    _linhaHistorico(
                      'Peso',
                      formatarPeso(
                        peso,
                      ),
                    ),

                    if ((dados[
                    'observacao'] ??
                        '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      _linhaHistorico(
                        'Observação',
                        dados[
                        'observacao']
                            .toString(),
                      ),

                    const SizedBox(
                        height: 8),

                    Align(
                      alignment:
                      Alignment
                          .centerRight,
                      child:
                      ElevatedButton
                          .icon(
                        onPressed: () {
                          editarFrete(
                            context,
                            id,
                            dados,
                          );
                        },
                        icon:
                        const Icon(
                          Icons.edit,
                        ),
                        label:
                        const Text(
                          'EDITAR',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // LINHA DO HISTÓRICO
  // ==========================================================

  Widget _linhaHistorico(
      String titulo,
      String valor,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$titulo:',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
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
}