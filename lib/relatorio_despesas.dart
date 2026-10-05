import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// MODELO DO RELATÓRIO DE DESPESAS
// ============================================================

class RelatorioDespesa {
  String id;
  String data;
  String motorista;
  String caminhao;
  String descricao;
  String cupomFiscal;
  String valor;
  bool possuiComprovante;

  // ==========================================================
  // COMPROVANTE SALVO NO FIRESTORE
  // ==========================================================

  String? comprovanteBase64;

  // ==========================================================
  // FOTO TEMPORÁRIA
  // ==========================================================

  XFile? comprovante;

  RelatorioDespesa({
    required this.id,
    required this.data,
    required this.motorista,
    required this.caminhao,
    required this.descricao,
    required this.cupomFiscal,
    required this.valor,
    this.possuiComprovante = false,
    this.comprovanteBase64,
    this.comprovante,
  });

  // ==========================================================
  // FIRESTORE -> MODELO
  // ==========================================================

  factory RelatorioDespesa.fromFirestore(
      DocumentSnapshot doc,
      ) {
    final dados = doc.data() as Map<String, dynamic>;

    return RelatorioDespesa(
      id: doc.id,
      data: dados['data']?.toString() ?? '',
      motorista: dados['motorista']?.toString() ?? '',
      caminhao: dados['caminhao']?.toString() ?? '',
      descricao: dados['descricao']?.toString() ?? '',
      cupomFiscal: dados['cupomFiscal']?.toString() ?? '',
      valor: dados['valor']?.toString() ?? '',
      possuiComprovante:
      dados['possuiComprovante'] == true,
      comprovanteBase64:
      dados['comprovanteBase64']?.toString(),
    );
  }
}

// ============================================================
// FIRESTORE
// ============================================================

final FirebaseFirestore _firestore =
    FirebaseFirestore.instance;

// ============================================================
// RELATÓRIO DE DESPESAS
// ============================================================

class RelatorioDespesasPage extends StatefulWidget {
  final String motorista;
  final String caminhao;
  final RelatorioDespesa? registroParaEditar;

  const RelatorioDespesasPage({
    super.key,
    required this.motorista,
    required this.caminhao,
    this.registroParaEditar,
  });

  @override
  State<RelatorioDespesasPage> createState() =>
      _RelatorioDespesasPageState();
}

class _RelatorioDespesasPageState
    extends State<RelatorioDespesasPage> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController dataController =
  TextEditingController();

  final TextEditingController descricaoController =
  TextEditingController();

  final TextEditingController cupomController =
  TextEditingController();

  final TextEditingController valorController =
  TextEditingController();

  // ==========================================================
  // COMPROVANTE
  // ==========================================================

  bool possuiComprovante = false;

  XFile? comprovante;

  String? comprovanteBase64Existente;

  // ==========================================================
  // SALVANDO
  // ==========================================================

  bool salvando = false;

  // ==========================================================
  // EDITANDO?
  // ==========================================================

  bool get editando =>
      widget.registroParaEditar != null;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    final registro =
        widget.registroParaEditar;

    if (registro != null) {
      dataController.text =
          registro.data;

      descricaoController.text =
          registro.descricao;

      cupomController.text =
          registro.cupomFiscal;

      valorController.text =
          registro.valor;

      possuiComprovante =
          registro.possuiComprovante;

      comprovante =
          registro.comprovante;

      comprovanteBase64Existente =
          registro.comprovanteBase64;
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    dataController.dispose();
    descricaoController.dispose();
    cupomController.dispose();
    valorController.dispose();

    super.dispose();
  }

  // ==========================================================
  // SELECIONAR DATA
  // ==========================================================

  Future<void> selecionarData() async {
    DateTime dataInicial =
    DateTime.now();

    if (dataController.text
        .trim()
        .isNotEmpty) {
      try {
        final partes =
        dataController.text.split('/');

        if (partes.length == 3) {
          final dia =
          int.parse(partes[0]);

          final mes =
          int.parse(partes[1]);

          final ano =
          int.parse(partes[2]);

          dataInicial =
              DateTime(ano, mes, dia);
        }
      } catch (_) {
        dataInicial =
            DateTime.now();
      }
    }

    final DateTime? dataSelecionada =
    await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate:
      DateTime(2000),
      lastDate:
      DateTime(2100),
      locale:
      const Locale('pt', 'BR'),
    );

    if (dataSelecionada != null) {
      final dia =
      dataSelecionada.day
          .toString()
          .padLeft(2, '0');

      final mes =
      dataSelecionada.month
          .toString()
          .padLeft(2, '0');

      final ano =
      dataSelecionada.year
          .toString();

      setState(() {
        dataController.text =
        '$dia/$mes/$ano';
      });
    }
  }

  // ==========================================================
  // TIRAR FOTO
  // ==========================================================

  Future<void> tirarFotoComprovante() async {
    try {
      final ImagePicker picker =
      ImagePicker();

      final XFile? foto =
      await picker.pickImage(
        source:
        ImageSource.camera,
        imageQuality: 95,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (foto == null) {
        return;
      }

      setState(() {
        comprovante = foto;
        possuiComprovante = true;
        comprovanteBase64Existente = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível abrir a câmera: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // ESCOLHER DA GALERIA
  // ==========================================================

  Future<void> escolherDaGaleria() async {
    try {
      final ImagePicker picker =
      ImagePicker();

      final XFile? foto =
      await picker.pickImage(
        source:
        ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (foto == null) {
        return;
      }

      setState(() {
        comprovante = foto;
        possuiComprovante = true;
        comprovanteBase64Existente = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível selecionar a imagem: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // OPÇÕES DO COMPROVANTE
  // ==========================================================

  Future<void> anexarComprovante() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:
                const Icon(
                  Icons.camera_alt,
                ),
                title:
                const Text(
                  'Tirar foto',
                ),
                onTap: () async {
                  Navigator.pop(
                    context,
                  );

                  await tirarFotoComprovante();
                },
              ),
              ListTile(
                leading:
                const Icon(
                  Icons.photo_library,
                ),
                title:
                const Text(
                  'Escolher da galeria',
                ),
                onTap: () async {
                  Navigator.pop(
                    context,
                  );

                  await escolherDaGaleria();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // REMOVER COMPROVANTE
  // ==========================================================

  void removerComprovante() {
    setState(() {
      possuiComprovante = false;
      comprovante = null;
      comprovanteBase64Existente = null;
    });
  }

  // ==========================================================
  // PREPARAR FOTO PARA O FIRESTORE
  //
  // Agora usamos:
  //
  // - até 2000px
  // - interpolação de melhor qualidade
  // - JPEG qualidade 88
  // - sem segunda compressão agressiva
  //
  // Isso preserva muito mais detalhes de notas,
  // cupons e recibos.
  // ==========================================================

  Future<String> prepararComprovanteBase64(
      XFile arquivo,
      ) async {
    final Uint8List bytes =
    await arquivo.readAsBytes();

    final img.Image? imagemOriginal =
    img.decodeImage(bytes);

    if (imagemOriginal == null) {
      throw Exception(
        'Não foi possível processar a imagem.',
      );
    }

    // ========================================================
    // REDIMENSIONAR
    // ========================================================

    img.Image imagem =
        imagemOriginal;

    const int tamanhoMaximo = 2000;

    if (imagem.width > tamanhoMaximo ||
        imagem.height > tamanhoMaximo) {
      imagem =
          img.copyResize(
            imagem,
            width:
            imagem.width >= imagem.height
                ? tamanhoMaximo
                : null,
            height:
            imagem.height > imagem.width
                ? tamanhoMaximo
                : null,
            interpolation:
            img.Interpolation.cubic,
          );
    }

    // ========================================================
    // COMPRIMIR COM QUALIDADE ALTA
    // ========================================================

    final List<int> jpg =
    img.encodeJpg(
      imagem,
      quality: 88,
    );

    // ========================================================
    // LIMITE DE SEGURANÇA
    //
    // Mantemos abaixo de aproximadamente 950 KB
    // para evitar problemas com o limite do documento
    // do Firestore.
    // ========================================================

    if (jpg.length >
        950 * 1024) {
      throw Exception(
        'A foto ficou muito grande. '
            'Tente tirar uma foto com menos zoom ou '
            'uma imagem com menor resolução.',
      );
    }

    return base64Encode(jpg);
  }

  // ==========================================================
  // SALVAR NO FIREBASE
  // ==========================================================

  Future<void> salvar() async {
    if (dataController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Informe a data.'),
        ),
      );

      return;
    }

    if (descricaoController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Informe a descrição.'),
        ),
      );

      return;
    }

    if (salvando) {
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      // ========================================================
      // NOVO ID OU ID EXISTENTE
      // ========================================================

      final String id =
      editando
          ? widget.registroParaEditar!.id
          : _firestore
          .collection(
        'relatorios_despesas',
      )
          .doc()
          .id;

      // ========================================================
      // COMPROVANTE
      // ========================================================

      String? base64Foto;

      if (possuiComprovante) {
        // ------------------------------------------------------
        // FOTO NOVA
        // ------------------------------------------------------

        if (comprovante != null) {
          base64Foto =
          await prepararComprovanteBase64(
            comprovante!,
          );
        }

        // ------------------------------------------------------
        // FOTO JÁ EXISTENTE
        // ------------------------------------------------------

        else if (
        comprovanteBase64Existente != null &&
            comprovanteBase64Existente!
                .isNotEmpty) {
          base64Foto =
              comprovanteBase64Existente;
        }
      }

      // ========================================================
      // DADOS
      // ========================================================

      final Map<String, dynamic> dados = {
        'data':
        dataController.text.trim(),

        'motorista':
        widget.motorista,

        'caminhao':
        widget.caminhao,

        'descricao':
        descricaoController.text.trim(),

        'cupomFiscal':
        cupomController.text.trim(),

        'valor':
        valorController.text.trim(),

        'possuiComprovante':
        possuiComprovante,

        'comprovanteBase64':
        base64Foto,

        'atualizadoEm':
        FieldValue.serverTimestamp(),
      };

      // ========================================================
      // NOVO
      // ========================================================

      if (!editando) {
        dados['criadoEm'] =
            FieldValue.serverTimestamp();

        await _firestore
            .collection(
          'relatorios_despesas',
        )
            .doc(id)
            .set(dados);
      }

      // ========================================================
      // EDITAR
      // ========================================================

      else {
        await _firestore
            .collection(
          'relatorios_despesas',
        )
            .doc(id)
            .update(dados);
      }

      // ========================================================
      // ATUALIZAR OBJETO LOCAL
      // ========================================================

      if (editando) {
        final registro =
        widget.registroParaEditar!;

        registro.data =
            dataController.text.trim();

        registro.descricao =
            descricaoController.text.trim();

        registro.cupomFiscal =
            cupomController.text.trim();

        registro.valor =
            valorController.text.trim();

        registro.possuiComprovante =
            possuiComprovante;

        registro.comprovante =
            comprovante;

        registro.comprovanteBase64 =
            base64Foto;
      }

      // ========================================================
      // SUCESSO
      // ========================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.green,
          content: Text(
            editando
                ? 'Lançamento atualizado no Firebase!'
                : 'Lançamento salvo no Firebase!',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.red,
          content: Text(
            'Erro ao salvar no Firebase:\n$e',
          ),
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
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editando
              ? 'Editar Relatório de Despesas'
              : 'Relatório de Despesas',
        ),
      ),
      body: SingleChildScrollView(
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
              CrossAxisAlignment.stretch,
              children: [
                // ==================================================
                // DADOS
                // ==================================================

                Card(
                  child: Padding(
                    padding:
                    const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DADOS DO LANÇAMENTO',
                          style:
                          TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            height: 15),
                        Text(
                          'Motorista: ${widget.motorista}',
                          style:
                          const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(
                            height: 8),
                        Text(
                          'Caminhão: ${widget.caminhao}',
                          style:
                          const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                    height: 18),

                // ==================================================
                // DATA
                // ==================================================

                TextField(
                  controller:
                  dataController,
                  readOnly: true,
                  onTap:
                  selecionarData,
                  decoration:
                  InputDecoration(
                    labelText:
                    'Data',
                    hintText:
                    'Selecione a data',
                    prefixIcon:
                    const Icon(
                      Icons.calendar_month,
                    ),
                    suffixIcon:
                    IconButton(
                      onPressed:
                      selecionarData,
                      icon:
                      const Icon(
                        Icons.calendar_today,
                      ),
                    ),
                    border:
                    const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                    height: 14),

                // ==================================================
                // DESCRIÇÃO
                // ==================================================

                campoTexto(
                  controller:
                  descricaoController,
                  label:
                  'Descrição',
                  hint:
                  'Digite a descrição',
                  icone:
                  Icons.description,
                  maxLines: 3,
                ),

                const SizedBox(
                    height: 14),

                // ==================================================
                // CUPOM
                // ==================================================

                campoTexto(
                  controller:
                  cupomController,
                  label:
                  'Cupom fiscal',
                  hint:
                  'Digite o número do cupom',
                  icone:
                  Icons.receipt,
                ),

                const SizedBox(
                    height: 14),

                // ==================================================
                // VALOR
                // ==================================================

                campoTexto(
                  controller:
                  valorController,
                  label:
                  'Valor',
                  hint:
                  'Ex.: 150,00',
                  icone:
                  Icons.attach_money,
                  teclado:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),
                ),

                const SizedBox(
                    height: 24),

                // ==================================================
                // COMPROVANTE
                // ==================================================

                const Text(
                  'COMPROVANTE',
                  style:
                  TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                    height: 8),

                Container(
                  padding:
                  const EdgeInsets.all(16),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    border:
                    Border.all(
                      color:
                      Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            possuiComprovante
                                ? Icons.check_circle
                                : Icons.receipt_long,
                            color:
                            possuiComprovante
                                ? Colors.green
                                : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(
                              width: 14),
                          Expanded(
                            child: Text(
                              possuiComprovante
                                  ? 'Comprovante anexado'
                                  : 'Nenhum comprovante anexado',
                              style:
                              const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                          if (possuiComprovante)
                            IconButton(
                              tooltip:
                              'Remover comprovante',
                              onPressed:
                              salvando
                                  ? null
                                  : removerComprovante,
                              icon:
                              const Icon(
                                Icons.delete_outline,
                              ),
                            ),
                        ],
                      ),

                      // ==================================================
                      // FOTO NOVA
                      // ==================================================

                      if (comprovante != null) ...[
                        const SizedBox(
                            height: 12),
                        FutureBuilder<
                            Uint8List>(
                          future:
                          comprovante!
                              .readAsBytes(),
                          builder:
                              (
                              context,
                              snapshot,
                              ) {
                            if (snapshot
                                .connectionState ==
                                ConnectionState
                                    .waiting) {
                              return const Padding(
                                padding:
                                EdgeInsets.all(
                                  20,
                                ),
                                child:
                                CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot
                                .hasData) {
                              return const Text(
                                'Não foi possível visualizar o comprovante.',
                              );
                            }

                            return ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                              child:
                              Image.memory(
                                snapshot.data!,
                                height:
                                220,
                                width:
                                double.infinity,
                                fit:
                                BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ]

                      // ==================================================
                      // FOTO JÁ SALVA
                      // ==================================================

                      else if (
                      possuiComprovante &&
                          comprovanteBase64Existente !=
                              null &&
                          comprovanteBase64Existente!
                              .isNotEmpty) ...[
                          const SizedBox(
                              height: 12),
                          Builder(
                            builder:
                                (context) {
                              try {
                                final Uint8List
                                bytes =
                                base64Decode(
                                  comprovanteBase64Existente!,
                                );

                                return ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(
                                    10,
                                  ),
                                  child:
                                  Image.memory(
                                    bytes,
                                    height:
                                    220,
                                    width:
                                    double.infinity,
                                    fit:
                                    BoxFit.cover,
                                  ),
                                );
                              } catch (_) {
                                return const Padding(
                                  padding:
                                  EdgeInsets.all(
                                    20,
                                  ),
                                  child: Text(
                                    'Não foi possível carregar o comprovante.',
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                    ],
                  ),
                ),

                const SizedBox(
                    height: 10),

                // ==================================================
                // BOTÃO COMPROVANTE
                // ==================================================

                OutlinedButton.icon(
                  onPressed:
                  salvando
                      ? null
                      : anexarComprovante,
                  icon:
                  const Icon(
                    Icons.camera_alt,
                  ),
                  label:
                  Text(
                    possuiComprovante
                        ? 'TROCAR COMPROVANTE'
                        : 'ANEXAR COMPROVANTE',
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    minimumSize:
                    const Size(
                      double.infinity,
                      52,
                    ),
                  ),
                ),

                const SizedBox(
                    height: 25),

                // ==================================================
                // SALVAR
                // ==================================================

                SizedBox(
                  height: 56,
                  child:
                  ElevatedButton.icon(
                    onPressed:
                    salvando
                        ? null
                        : salvar,
                    icon:
                    salvando
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                      ),
                    )
                        : Icon(
                      editando
                          ? Icons.save
                          : Icons.check,
                    ),
                    label:
                    Text(
                      salvando
                          ? 'SALVANDO...'
                          : editando
                          ? 'SALVAR ALTERAÇÕES'
                          : 'SALVAR LANÇAMENTO',
                      style:
                      const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
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

  // ==========================================================
  // CAMPO DE TEXTO
  // ==========================================================

  Widget campoTexto({
    required TextEditingController
    controller,
    required String label,
    required String hint,
    required IconData icone,
    TextInputType? teclado,
    int maxLines = 1,
  }) {
    return TextField(
      controller:
      controller,
      keyboardType:
      teclado,
      maxLines:
      maxLines,
      decoration:
      InputDecoration(
        labelText:
        label,
        hintText:
        hint,
        prefixIcon:
        maxLines == 1
            ? Icon(icone)
            : Padding(
          padding:
          const EdgeInsets.only(
            bottom: 45,
          ),
          child:
          Icon(icone),
        ),
        border:
        const OutlineInputBorder(),
      ),
    );
  }
}

// ============================================================
// HISTÓRICO DE DESPESAS
// ============================================================

class HistoricoDespesasPage
    extends StatefulWidget {
  final String motorista;
  final String caminhao;

  const HistoricoDespesasPage({
    super.key,
    required this.motorista,
    required this.caminhao,
  });

  @override
  State<HistoricoDespesasPage> createState() =>
      _HistoricoDespesasPageState();
}

class _HistoricoDespesasPageState
    extends State<HistoricoDespesasPage> {
  // ==========================================================
  // EDITAR
  // ==========================================================

  void editar(
      RelatorioDespesa registro,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RelatorioDespesasPage(
              motorista:
              widget.motorista,
              caminhao:
              widget.caminhao,
              registroParaEditar:
              registro,
            ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
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
          'Meus Lançamentos',
        ),
      ),
      body:
      StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(
          'relatorios_despesas',
        )
            .where(
          'motorista',
          isEqualTo:
          widget.motorista,
        )
            .where(
          'caminhao',
          isEqualTo:
          widget.caminhao,
        )
            .snapshots(),
        builder:
            (context, snapshot) {
          if (snapshot
              .connectionState ==
              ConnectionState
                  .waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  25,
                ),
                child: Text(
                  'Erro ao carregar os lançamentos:\n\n${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding:
                EdgeInsets.all(30),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 70,
                      color: Colors.grey,
                    ),
                    SizedBox(
                        height: 15),
                    Text(
                      'Nenhum lançamento encontrado.',
                      textAlign:
                      TextAlign.center,
                      style:
                      TextStyle(
                        fontSize: 18,
                        color:
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ======================================================
          // CONVERTER FIRESTORE
          // ======================================================

          final registros =
          snapshot.data!.docs
              .map(
                (doc) =>
                RelatorioDespesa
                    .fromFirestore(
                  doc,
                ),
          )
              .toList();

          // ======================================================
          // ORDENAR
          // ======================================================

          registros.sort(
                (a, b) =>
                b.id.compareTo(a.id),
          );

          // ======================================================
          // LISTA
          // ======================================================

          return ListView.builder(
            padding:
            const EdgeInsets.all(16),
            itemCount:
            registros.length,
            itemBuilder:
                (context, index) {
              final registro =
              registros[index];

              return Card(
                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),
                child: ListTile(
                  leading:
                  CircleAvatar(
                    child: Icon(
                      registro
                          .possuiComprovante
                          ? Icons.photo
                          : Icons
                          .receipt_long,
                    ),
                  ),
                  title:
                  Text(
                    registro.descricao,
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  subtitle:
                  Text(
                    'Data: ${registro.data}\n'
                        'Valor: ${registro.valor.isEmpty ? 'Não informado' : 'R\$ ${registro.valor}'}',
                  ),
                  isThreeLine:
                  true,
                  trailing:
                  IconButton(
                    tooltip:
                    'Editar',
                    onPressed:
                        () => editar(
                      registro,
                    ),
                    icon:
                    const Icon(
                      Icons.edit,
                    ),
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