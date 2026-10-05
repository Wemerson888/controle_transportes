import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// MOTORISTAS
// ============================================================

class MotoristasPage extends StatelessWidget {
  const MotoristasPage({super.key});

  // ==========================================================
  // ATIVAR / DESATIVAR
  // ==========================================================

  Future<void> alternarStatus(
      BuildContext context,
      DocumentSnapshot motorista,
      bool ativoAtual,
      ) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(motorista.id)
        .update({
      'ativo': !ativoAtual,
      'editadoEm': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ativoAtual
              ? 'Motorista desativado.'
              : 'Motorista ativado.',
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
          'MOTORISTAS',
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where(
          'tipo',
          isEqualTo: 'motorista',
        )
            .orderBy('nome')
            .snapshots(),

        builder: (context, snapshot) {
          // ==================================================
          // CARREGANDO
          // ==================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ==================================================
          // ERRO
          // ==================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar motoristas:\n\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final motoristas =
              snapshot.data?.docs ?? [];

          // ==================================================
          // NENHUM MOTORISTA
          // ==================================================

          if (motoristas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 70,
                    ),

                    SizedBox(height: 15),

                    Text(
                      'Nenhum motorista cadastrado.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Os motoristas serão cadastrados pelo ADM.',
                      textAlign:
                      TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // ==================================================
          // LISTA
          // ==================================================

          return ListView.builder(
            padding: const EdgeInsets.all(16),

            itemCount: motoristas.length,

            itemBuilder: (context, index) {
              final motorista =
              motoristas[index];

              final dados =
              motorista.data()
              as Map<String, dynamic>;

              final nome =
                  dados['nome'] ??
                      'Motorista';

              final email =
                  dados['email'] ??
                      '';

              final ativo =
                  dados['ativo'] == true;

              return Card(
                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),

                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),

                  // ==================================================
                  // ÍCONE
                  // ==================================================

                  leading: CircleAvatar(
                    radius: 25,
                    child: Icon(
                      ativo
                          ? Icons.person
                          : Icons.person_off,
                    ),
                  ),

                  // ==================================================
                  // NOME / EMAIL / STATUS
                  // ==================================================

                  title: Text(
                    nome.toString(),
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  subtitle: Padding(
                    padding:
                    const EdgeInsets.only(
                      top: 5,
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        Text(
                          email.toString(),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          ativo
                              ? 'ATIVO'
                              : 'INATIVO',

                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color: ativo
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // MENU
                  // ==================================================

                  trailing:
                  PopupMenuButton<String>(
                    onSelected:
                        (opcao) {
                      if (opcao ==
                          'status') {
                        alternarStatus(
                          context,
                          motorista,
                          ativo,
                        );
                      }
                    },

                    itemBuilder:
                        (context) {
                      return [
                        PopupMenuItem(
                          value: 'status',

                          child: Row(
                            children: [
                              Icon(
                                ativo
                                    ? Icons
                                    .person_off
                                    : Icons
                                    .person,
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Text(
                                ativo
                                    ? 'Desativar'
                                    : 'Ativar',
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
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