import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// CLIENTES
// ============================================================

class ClientesLojasPage extends StatefulWidget {
  const ClientesLojasPage({super.key});

  @override
  State<ClientesLojasPage> createState() =>
      _ClientesLojasPageState();
}

class _ClientesLojasPageState extends State<ClientesLojasPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _pesquisaController =
  TextEditingController();

  String _pesquisa = '';

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

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
  // CADASTRAR CLIENTE
  // ==========================================================

  Future<void> _cadastrarCliente() async {
    final nomeController = TextEditingController();
    final freteController = TextEditingController();

    // Guardamos o contexto da página.
    // NÃO usaremos o contexto interno do AlertDialog
    // para acessar o ScaffoldMessenger.
    final pageContext = context;

    final resultado =
    await showDialog<Map<String, dynamic>>(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Novo Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  autofocus: true,
                  textCapitalization:
                  TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome do cliente',
                    hintText: 'Digite o nome do cliente',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: freteController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor do frete',
                    hintText: 'Ex.: 85,00',
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: 'R\$ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('CANCELAR'),
            ),

            ElevatedButton.icon(
              onPressed: () {
                final nome =
                nomeController.text.trim();

                final freteTexto =
                freteController.text
                    .trim()
                    .replaceAll('.', '')
                    .replaceAll(',', '.');

                final frete =
                double.tryParse(freteTexto);

                if (nome.isEmpty ||
                    frete == null ||
                    frete <= 0) {
                  // Usa o contexto da página,
                  // e não o contexto do AlertDialog.
                  ScaffoldMessenger.of(pageContext)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Informe o nome do cliente e um valor de frete válido.',
                        ),
                      ),
                    );

                  return;
                }

                Navigator.of(dialogContext).pop(
                  {
                    'nome': nome,
                    'frete': frete,
                  },
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('CADASTRAR'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nomeController.dispose();
      freteController.dispose();
    });

    if (resultado == null) {
      return;
    }

    final nomeFinal =
    resultado['nome'].toString().trim();

    final frete =
    resultado['frete'];

    // ========================================================
    // VERIFICAR CLIENTE DUPLICADO
    // ========================================================

    try {
      final existente = await _firestore
          .collection('clientes')
          .where(
        'nomeBusca',
        isEqualTo: nomeFinal.toLowerCase(),
      )
          .limit(1)
          .get();

      if (existente.docs.isNotEmpty) {
        _mostrarMensagem(
          'Este cliente já está cadastrado.',
        );
        return;
      }

      // ======================================================
      // CRIAR CLIENTE PRIVADO
      // ======================================================
      //
      // O frete fica somente nesta coleção.
      // O motorista não terá acesso a ela.
      //
      // ======================================================

      final novoCliente =
      await _firestore
          .collection('clientes')
          .add({
        'nome': nomeFinal,
        'nomeBusca': nomeFinal.toLowerCase(),
        'frete': frete,
        'ativo': true,
        'criadoEm':
        FieldValue.serverTimestamp(),
      });

      // ======================================================
      // CRIAR VERSÃO PARA MOTORISTAS
      // ======================================================
      //
      // IMPORTANTE:
      // Não envia o valor do frete.
      //
      // ======================================================

      await _atualizarClienteMotorista(
        clienteId: novoCliente.id,
        nome: nomeFinal,
        ativo: true,
      );

      _mostrarMensagem(
        'Cliente cadastrado com sucesso.',
        cor: Colors.green,
      );
    } catch (e) {
      _mostrarMensagem(
        'Erro ao cadastrar cliente: $e',
      );
    }
  }

  // ==========================================================
  // ATUALIZAR CLIENTE PARA MOTORISTAS
  // ==========================================================

  Future<void> _atualizarClienteMotorista({
    required String clienteId,
    required String nome,
    required bool ativo,
  }) async {
    await _firestore
        .collection('clientes_motoristas')
        .doc(clienteId)
        .set(
      {
        'clienteId': clienteId,
        'nome': nome,
        'ativo': ativo,
        'atualizadoEm':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ==========================================================
  // EDITAR CLIENTE
  // ==========================================================

  Future<void> _editarCliente(
      DocumentSnapshot cliente,
      ) async {
    final dados =
    cliente.data()
    as Map<String, dynamic>;

    final nomeController =
    TextEditingController(
      text: dados['nome']?.toString() ?? '',
    );

    final freteController =
    TextEditingController(
      text: _formatarValorInput(
        dados['frete'],
      ),
    );

    final pageContext = context;

    final resultado =
    await showDialog<Map<String, dynamic>>(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Editar Cliente',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  autofocus: true,
                  textCapitalization:
                  TextCapitalization.words,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Nome do cliente',
                    prefixIcon:
                    Icon(Icons.business),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: freteController,
                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Valor do frete',
                    prefixIcon: Icon(
                      Icons.attach_money,
                    ),
                    prefixText: 'R\$ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child:
              const Text('CANCELAR'),
            ),

            ElevatedButton(
              onPressed: () {
                final nome =
                nomeController.text.trim();

                final freteTexto =
                freteController.text
                    .trim()
                    .replaceAll('.', '')
                    .replaceAll(',', '.');

                final frete =
                double.tryParse(
                  freteTexto,
                );

                if (nome.isEmpty ||
                    frete == null ||
                    frete <= 0) {
                  ScaffoldMessenger.of(pageContext)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Informe dados válidos.',
                        ),
                      ),
                    );

                  return;
                }

                Navigator.of(dialogContext).pop(
                  {
                    'nome': nome,
                    'frete': frete,
                  },
                );
              },
              child:
              const Text('SALVAR'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nomeController.dispose();
      freteController.dispose();
    });

    if (resultado == null) {
      return;
    }

    final nomeFinal =
    resultado['nome'].toString().trim();

    final frete =
    resultado['frete'];

    try {
      // ======================================================
      // ATUALIZAR CLIENTE PRIVADO
      // ======================================================

      await cliente.reference.update({
        'nome': nomeFinal,
        'nomeBusca':
        nomeFinal.toLowerCase(),
        'frete': frete,
        'editadoEm':
        FieldValue.serverTimestamp(),
      });

      // ======================================================
      // ATUALIZAR CLIENTE PARA MOTORISTA
      // ======================================================

      final ativo =
          dados['ativo'] ?? true;

      await _atualizarClienteMotorista(
        clienteId: cliente.id,
        nome: nomeFinal,
        ativo: ativo,
      );

      _mostrarMensagem(
        'Cliente atualizado.',
        cor: Colors.green,
      );
    } catch (e) {
      _mostrarMensagem(
        'Erro ao atualizar cliente: $e',
      );
    }
  }

  // ==========================================================
  // ATIVAR / DESATIVAR CLIENTE
  // ==========================================================

  Future<void> _alternarCliente(
      DocumentSnapshot cliente,
      bool ativoAtual,
      ) async {
    final novoStatus = !ativoAtual;

    try {
      // ======================================================
      // ATUALIZAR CLIENTE PRIVADO
      // ======================================================

      await cliente.reference.update({
        'ativo': novoStatus,
        'editadoEm':
        FieldValue.serverTimestamp(),
      });

      // ======================================================
      // ATUALIZAR CLIENTE PARA MOTORISTAS
      // ======================================================

      final dados =
      cliente.data()
      as Map<String, dynamic>;

      final nome =
          dados['nome']?.toString() ?? '';

      await _atualizarClienteMotorista(
        clienteId: cliente.id,
        nome: nome,
        ativo: novoStatus,
      );

      _mostrarMensagem(
        novoStatus
            ? 'Cliente ativado.'
            : 'Cliente desativado.',
        cor: novoStatus
            ? Colors.green
            : Colors.orange,
      );
    } catch (e) {
      _mostrarMensagem(
        'Erro ao alterar cliente: $e',
      );
    }
  }

  // ==========================================================
  // APAGAR CLIENTE
  // ==========================================================

  Future<void> _apagarCliente(
      DocumentSnapshot cliente,
      ) async {
    final dados =
    cliente.data() as Map<String, dynamic>;

    final nome =
        dados['nome']?.toString() ?? 'Cliente';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar cliente?'),
          content: Text(
            'Tem certeza que deseja apagar o cliente "$nome"?\n\n'
                'Os fretes já lançados continuarão no histórico. '
                'O cliente apenas será removido do cadastro e da seleção dos motoristas.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete),
              label: const Text('APAGAR'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.delete(cliente.reference);

        transaction.delete(
          _firestore
              .collection('clientes_motoristas')
              .doc(cliente.id),
        );
      });

      _mostrarMensagem(
        'Cliente "$nome" apagado com sucesso.',
        cor: Colors.green,
      );
    } catch (e) {
      _mostrarMensagem(
        'Erro ao apagar cliente: $e',
        cor: Colors.red,
      );
    }
  }

  // ==========================================================
  // FORMATAR VALOR PARA INPUT
  // ==========================================================

  String _formatarValorInput(
      dynamic valor,
      ) {
    if (valor == null) {
      return '';
    }

    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(
      valor.toString(),
    ) ??
        0;

    return numero
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  // ==========================================================
  // FORMATAR MOEDA
  // ==========================================================

  String _formatarMoeda(
      dynamic valor,
      ) {
    if (valor == null) {
      return 'R\$ 0,00';
    }

    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(
      valor.toString(),
    ) ??
        0;

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ==========================================================
  // CARD DO CLIENTE
  // ==========================================================

  Widget _cardCliente(
      DocumentSnapshot cliente,
      ) {
    final dados =
    cliente.data()
    as Map<String, dynamic>;

    final nome =
        dados['nome'] ?? 'Cliente';

    final frete =
    dados['frete'];

    final ativo =
        dados['ativo'] ?? true;

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            ativo
                ? Icons.business
                : Icons.business_outlined,
          ),
        ),

        title: Text(
          nome,
          style:
          const TextStyle(
            fontWeight:
            FontWeight.bold,
            fontSize: 17,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),

            Text(
              _formatarMoeda(frete),
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              ativo
                  ? 'CLIENTE ATIVO'
                  : 'CLIENTE INATIVO',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.bold,
                color: ativo
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
          ],
        ),

        trailing:
        PopupMenuButton<String>(
          onSelected: (opcao) {
            if (opcao == 'editar') {
              _editarCliente(cliente);
            }

            if (opcao == 'status') {
              _alternarCliente(
                cliente,
                ativo,
              );
            }

            if (opcao == 'apagar') {
              _apagarCliente(cliente);
            }
          },
          itemBuilder: (context) {
            return [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 10),
                    Text('Editar cliente'),
                  ],
                ),
              ),

              PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(
                      ativo
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      ativo
                          ? 'Desativar cliente'
                          : 'Ativar cliente',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'apagar',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Apagar cliente',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
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
        title: const Text(
          'CLIENTES',
        ),
        centerTitle: true,
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _cadastrarCliente,
        icon: const Icon(
          Icons.person_add,
        ),
        label: const Text(
          'NOVO CLIENTE',
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller: _pesquisaController,
              onChanged: (valor) {
                setState(() {
                  _pesquisa = valor.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Pesquisar cliente',
                hintText: 'Digite o nome do cliente',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _pesquisa.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _pesquisaController.clear();
                    setState(() {
                      _pesquisa = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('clientes')
                  .orderBy('nome')
                  .snapshots(),

              builder:
                  (context, snapshot) {
                if (snapshot
                    .connectionState ==
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
                      const EdgeInsets.all(
                        24,
                      ),
                      child: Text(
                        'Erro ao carregar clientes:\n'
                            '${snapshot.error}',
                        textAlign:
                        TextAlign.center,
                      ),
                    ),
                  );
                }

                final clientes =
                    snapshot.data?.docs ?? [];

                if (clientes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        30,
                      ),
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.business,
                            size: 70,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          const Text(
                            'Nenhum cliente cadastrado.',
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            'Cadastre o primeiro cliente para começar.',
                            textAlign:
                            TextAlign.center,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          ElevatedButton.icon(
                            onPressed:
                            _cadastrarCliente,
                            icon: const Icon(
                              Icons.person_add,
                            ),
                            label:
                            const Text(
                              'CADASTRAR CLIENTE',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final clientesFiltrados =
                clientes.where((cliente) {
                  final dados =
                  cliente.data()
                  as Map<String, dynamic>;

                  final nome =
                      dados['nome']
                          ?.toString()
                          .toLowerCase() ??
                          '';

                  return _pesquisa.isEmpty ||
                      nome.contains(_pesquisa);
                }).toList();

                if (clientesFiltrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 60,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _pesquisa.isEmpty
                                ? 'Nenhum cliente cadastrado.'
                                : 'Nenhum cliente encontrado.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_pesquisa.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Tente pesquisar por outro nome.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    100,
                  ),
                  itemCount:
                  clientesFiltrados.length,
                  itemBuilder:
                      (context, index) {
                    return _cardCliente(
                      clientesFiltrados[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}