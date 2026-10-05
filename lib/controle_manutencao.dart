import 'package:flutter/material.dart';

class ControleManutencaoPage extends StatefulWidget {
  const ControleManutencaoPage({super.key});

  @override
  State<ControleManutencaoPage> createState() => _ControleManutencaoPageState();
}

class _ControleManutencaoPageState extends State<ControleManutencaoPage> {
  final _formKey = GlobalKey<FormState>();

  final _dataController = TextEditingController();
  final _kmInicialController = TextEditingController();
  final _kmFinalController = TextEditingController();
  final _kmRodadoController = TextEditingController();
  final _pecaServicoController = TextEditingController();
  final _observacaoController = TextEditingController();

  String? _tipoManutencao;
  final List<Map<String, String>> _lancamentos = [];

  @override
  void dispose() {
    _dataController.dispose();
    _kmInicialController.dispose();
    _kmFinalController.dispose();
    _kmRodadoController.dispose();
    _pecaServicoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _calcularKmRodado() {
    final inicial = double.tryParse(
      _kmInicialController.text.replaceAll(',', '.'),
    );
    final finalKm = double.tryParse(
      _kmFinalController.text.replaceAll(',', '.'),
    );

    if (inicial != null && finalKm != null && finalKm >= inicial) {
      final resultado = finalKm - inicial;
      _kmRodadoController.text =
          resultado.toStringAsFixed(0).replaceAll('.', ',');
    }
  }

  void _salvarLancamento() {
    if (!_formKey.currentState!.validate()) return;

    _lancamentos.add({
      'data': _dataController.text,
      'kmInicial': _kmInicialController.text,
      'kmFinal': _kmFinalController.text,
      'kmRodado': _kmRodadoController.text,
      'tipo': _tipoManutencao ?? '',
      'pecaServico': _pecaServicoController.text,
      'observacao': _observacaoController.text,
    });

    _limparFormulario();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lançamento salvo com sucesso!'),
      ),
    );
    setState(() {});
  }

  void _editarLancamento(int index) {
    final item = _lancamentos[index];

    _dataController.text = item['data'] ?? '';
    _kmInicialController.text = item['kmInicial'] ?? '';
    _kmFinalController.text = item['kmFinal'] ?? '';
    _kmRodadoController.text = item['kmRodado'] ?? '';
    _pecaServicoController.text = item['pecaServico'] ?? '';
    _observacaoController.text = item['observacao'] ?? '';
    _tipoManutencao =
    (item['tipo']?.isEmpty ?? true) ? null : item['tipo'];

    setState(() {});

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar lançamento'),
          content: const Text(
            'Os dados foram carregados no formulário. '
                'Edite as informações e salve novamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _excluirLancamento(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text(
          'Esta ação remove o lançamento desta lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _lancamentos.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  void _limparFormulario() {
    _dataController.clear();
    _kmInicialController.clear();
    _kmFinalController.clear();
    _kmRodadoController.clear();
    _pecaServicoController.clear();
    _observacaoController.clear();

    setState(() {
      _tipoManutencao = null;
    });
  }

  InputDecoration _decoracao(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decoracao(label, icon),
      validator: validator,
      onChanged: (_) => onChanged?.call(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Manutenção'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'CONTROLE DE MANUTENÇÃO',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Registre a manutenção realizada no veículo.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _campo(
                      controller: _dataController,
                      label: 'Data',
                      icon: Icons.calendar_month,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a data';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _tipoManutencao,
                      decoration:
                      _decoracao('Tipo de manutenção', Icons.build),
                      items: const [
                        DropdownMenuItem(
                          value: 'Preventiva',
                          child: Text('Preventiva'),
                        ),
                        DropdownMenuItem(
                          value: 'Corretiva',
                          child: Text('Corretiva'),
                        ),
                        DropdownMenuItem(
                          value: 'Revisão',
                          child: Text('Revisão'),
                        ),
                        DropdownMenuItem(
                          value: 'Outro',
                          child: Text('Outro'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _tipoManutencao = value;
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Selecione o tipo' : null,
                    ),
                    const SizedBox(height: 12),

                    _campo(
                      controller: _kmInicialController,
                      label: 'KM inicial',
                      icon: Icons.speed,
                      keyboardType: TextInputType.number,
                      onChanged: _calcularKmRodado,
                    ),
                    const SizedBox(height: 12),

                    _campo(
                      controller: _kmFinalController,
                      label: 'KM final',
                      icon: Icons.speed,
                      keyboardType: TextInputType.number,
                      onChanged: _calcularKmRodado,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o KM final';
                        }

                        final inicial = double.tryParse(
                          _kmInicialController.text.replaceAll(',', '.'),
                        );
                        final finalKm = double.tryParse(
                          value.replaceAll(',', '.'),
                        );

                        if (inicial != null &&
                            finalKm != null &&
                            finalKm < inicial) {
                          return 'O KM final não pode ser menor que o inicial';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    _campo(
                      controller: _kmRodadoController,
                      label: 'KM rodado',
                      icon: Icons.route,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    _campo(
                      controller: _pecaServicoController,
                      label: 'Nome da peça ou serviço',
                      icon: Icons.receipt_long,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a peça ou serviço';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _observacaoController,
                      maxLines: 3,
                      decoration: _decoracao(
                        'Observação',
                        Icons.notes,
                      ),
                    ),
                    const SizedBox(height: 18),

                    FilledButton.icon(
                      onPressed: _salvarLancamento,
                      icon: const Icon(Icons.save),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'SALVAR LANÇAMENTO',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    if (_lancamentos.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'LANÇAMENTOS DO MOTORISTA',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...List.generate(
                        _lancamentos.length,
                            (index) {
                          final item = _lancamentos[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.build),
                              ),
                              title: Text(
                                item['pecaServico'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Data: ${item['data']}'
                                    '\nKM: ${item['kmInicial']} → ${item['kmFinal']}'
                                    '  |  Rodado: ${item['kmRodado']}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'editar') {
                                    _editarLancamento(index);
                                  } else if (value == 'excluir') {
                                    _excluirLancamento(index);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'excluir',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
