import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import 'selecao_caminhao.dart';

class ControleFrotasPage extends StatelessWidget {
  const ControleFrotasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONTROLE DE FROTAS'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: frotaCaminhoes.length,
          itemBuilder: (context, index) {
            final caminhao = frotaCaminhoes[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.local_shipping),
                ),
                title: Text(
                  caminhao.frota,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${caminhao.placa} • ${caminhao.modelo}',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DespesasFrotaPage(
                        caminhao: caminhao,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class DespesasFrotaPage extends StatefulWidget {
  final Caminhao caminhao;

  const DespesasFrotaPage({
    super.key,
    required this.caminhao,
  });

  @override
  State<DespesasFrotaPage> createState() =>
      _DespesasFrotaPageState();
}

class _DespesasFrotaPageState
    extends State<DespesasFrotaPage> {
  double _numero(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    final texto =
        valor?.toString().trim() ?? '';

    return double.tryParse(
      texto
          .replaceAll('.', '')
          .replaceAll(',', '.'),
    ) ??
        0;
  }

  String _formatarValor(dynamic valor) {
    final numero = _numero(valor);

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarData(String valor) {
    if (valor.trim().isEmpty) {
      return '--';
    }

    return valor;
  }

  bool _pertenceAoCaminhao(
      Map<String, dynamic> dados,
      ) {
    final salvo =
    (dados['caminhao']?.toString() ?? '')
        .trim()
        .toUpperCase();

    final frota =
    widget.caminhao.frota.toUpperCase();

    final placa =
    widget.caminhao.placa.toUpperCase();

    final nomeCompleto =
    '${widget.caminhao.frota} - '
        '${widget.caminhao.placa}'
        .toUpperCase();

    return salvo == nomeCompleto ||
        salvo.contains(frota) ||
        salvo.contains(placa);
  }

  // ============================================================
  // BAIXAR COMPROVANTE
  // ============================================================
  void _baixarComprovante(
      String base64,
      String descricao,
      ) {
    try {
      final Uint8List bytes =
      base64Decode(base64);

      final blob = html.Blob(
        [bytes],
        'image/jpeg',
      );

      final url =
      html.Url.createObjectUrlFromBlob(blob);

      final nomeArquivo =
      _nomeArquivo(descricao);

      final link = html.AnchorElement(
        href: url,
      )
        ..setAttribute(
          'download',
          '$nomeArquivo.jpg',
        )
        ..style.display = 'none';

      html.document.body?.children.add(link);

      link.click();

      link.remove();

      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Comprovante baixado com sucesso.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível baixar o comprovante: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _nomeArquivo(String descricao) {
    var nome = descricao.trim();

    if (nome.isEmpty) {
      nome = 'comprovante';
    }

    nome = nome
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return 'comprovante_$nome';
  }

  // ============================================================
  // VISUALIZAR COMPROVANTE
  // ============================================================
  void _mostrarComprovante(
      String base64,
      String descricao,
      ) {
    try {
      final Uint8List bytes =
      base64Decode(base64);

      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 800,
                maxHeight: 850,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            descricao,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                          icon: const Icon(
                            Icons.close,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Flexible(
                    child: InteractiveViewer(
                      child: SingleChildScrollView(
                        padding:
                        const EdgeInsets.all(16),
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // BOTÕES
                  // ==================================================
                  Padding(
                    padding:
                    const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                            icon: const Icon(
                              Icons.close,
                            ),
                            label: const Text(
                              'FECHAR',
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _baixarComprovante(
                                base64,
                                descricao,
                              );
                            },
                            icon: const Icon(
                              Icons.download,
                            ),
                            label: const Text(
                              'BAIXAR',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível abrir o comprovante: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('relatorios_despesas')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DESPESAS — ${widget.caminhao.frota}',
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar despesas:\n\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documentos = snapshot.data?.docs
              .where(
                (doc) =>
                _pertenceAoCaminhao(
                  doc.data(),
                ),
          )
              .toList() ??
              [];

          documentos.sort(
                (a, b) {
              final dataA =
                  a.data()['data']?.toString() ??
                      '';

              final dataB =
                  b.data()['data']?.toString() ??
                      '';

              return dataB.compareTo(dataA);
            },
          );

          final total =
          documentos.fold<double>(
            0,
                (soma, documento) {
              return soma +
                  _numero(
                    documento.data()['valor'],
                  );
            },
          );

          return ListView(
            padding:
            const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding:
                  const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 27,
                            child: Icon(
                              Icons.local_shipping,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.caminhao.frota,
                                  style:
                                  const TextStyle(
                                    fontSize: 21,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '${widget.caminhao.placa} • '
                                      '${widget.caminhao.modelo}',
                                  style:
                                  const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'TOTAL DE DESPESAS',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey.shade700,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatarValor(total),
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${documentos.length} lançamento(s)',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              if (documentos.isEmpty)
                const Card(
                  child: Padding(
                    padding:
                    EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhuma despesa encontrada '
                              'para este caminhão.',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...documentos.map(
                      (documento) =>
                      _cardDespesa(documento),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardDespesa(
      QueryDocumentSnapshot<
          Map<String, dynamic>>
      documento,
      ) {
    final dados =
    documento.data();

    final data =
        dados['data']?.toString() ?? '';

    final motorista =
        dados['motorista']?.toString() ??
            '--';

    final descricao =
        dados['descricao']?.toString() ??
            '--';

    final cupom =
        dados['cupomFiscal']?.toString() ??
            '';

    final valor =
    dados['valor'];

    final base64 =
        dados['comprovanteBase64']
            ?.toString()
            .trim() ??
            '';

    final possuiComprovante =
        dados['possuiComprovante'] == true &&
            base64.isNotEmpty;

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
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Icon(
                    possuiComprovante
                        ? Icons.receipt_long
                        : Icons
                        .receipt_long_outlined,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        descricao,
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Data: '
                            '${_formatarData(data)}',
                      ),

                      Text(
                        'Motorista: '
                            '$motorista',
                      ),

                      if (cupom.trim().isNotEmpty)
                        Text(
                          'Cupom/Nota: $cupom',
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  _formatarValor(valor),
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            if (possuiComprovante) ...[
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _mostrarComprovante(
                      base64,
                      descricao,
                    );
                  },
                  icon: const Icon(
                    Icons.visibility,
                  ),
                  label: const Text(
                    'VER COMPROVANTE',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}