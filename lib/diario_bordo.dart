import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'selecao_caminhao.dart';

class DiarioBordoPage extends StatefulWidget {
  final String motorista;
  final Caminhao caminhao;

  const DiarioBordoPage({
    super.key,
    required this.motorista,
    required this.caminhao,
  });

  @override
  State<DiarioBordoPage> createState() => _DiarioBordoPageState();
}

class _DiarioBordoPageState extends State<DiarioBordoPage> {
  final _formKey = GlobalKey<FormState>();

  final origemController = TextEditingController();
  final destinoController = TextEditingController();
  final kmInicialController = TextEditingController();
  final kmFinalController = TextEditingController();

  DateTime? dataSaida;
  TimeOfDay? horaSaida;

  DateTime? dataChegada;
  TimeOfDay? horaChegada;

  bool salvando = false;

  @override
  void dispose() {
    origemController.dispose();
    destinoController.dispose();
    kmInicialController.dispose();
    kmFinalController.dispose();
    super.dispose();
  }

  // ==========================================================
  // DATA DE SAÍDA
  // ==========================================================

  Future<void> selecionarDataSaida() async {
    final hoje = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: dataSaida ?? hoje,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'SELECIONE A DATA DE SAÍDA',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );

    if (data != null) {
      setState(() {
        dataSaida = data;
      });
    }
  }

  // ==========================================================
  // HORA DE SAÍDA
  // ==========================================================

  Future<void> selecionarHoraSaida() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: horaSaida ?? TimeOfDay.now(),
      helpText: 'SELECIONE A HORA DE SAÍDA',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );

    if (hora != null) {
      setState(() {
        horaSaida = hora;
      });
    }
  }

  // ==========================================================
  // DATA DE CHEGADA
  // ==========================================================

  Future<void> selecionarDataChegada() async {
    final hoje = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: dataChegada ?? dataSaida ?? hoje,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'SELECIONE A DATA DE CHEGADA',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );

    if (data != null) {
      setState(() {
        dataChegada = data;
      });
    }
  }

  // ==========================================================
  // HORA DE CHEGADA
  // ==========================================================

  Future<void> selecionarHoraChegada() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: horaChegada ?? TimeOfDay.now(),
      helpText: 'SELECIONE A HORA DE CHEGADA',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );

    if (hora != null) {
      setState(() {
        horaChegada = hora;
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
  // FORMATAR HORA
  // ==========================================================

  String formatarHora(TimeOfDay? hora) {
    if (hora == null) {
      return 'Selecionar hora';
    }

    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');

    return '$h:$m';
  }

  String formatarHoraTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return '-';
    }

    final data = timestamp.toDate();

    final h = data.hour.toString().padLeft(2, '0');
    final m = data.minute.toString().padLeft(2, '0');

    return '$h:$m';
  }

  // ==========================================================
  // FORMATAR KM
  // ==========================================================

  String formatarKm(dynamic valor) {
    if (valor == null) {
      return '-';
    }

    final numero = double.tryParse(
      valor.toString().replaceAll(',', '.'),
    );

    if (numero == null) {
      return valor.toString();
    }

    // Se for número inteiro, não mostra .0
    if (numero == numero.truncateToDouble()) {
      return numero.toInt().toString();
    }

    // Se tiver casas decimais reais, mantém
    return numero.toString();
  }

  // ==========================================================
  // COMBINAR DATA + HORA
  // ==========================================================

  DateTime combinarDataHora(
      DateTime data,
      TimeOfDay hora,
      ) {
    return DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );
  }

  // ==========================================================
  // SALVAR
  // ==========================================================

  Future<void> salvarDiario() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (dataSaida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data de saída.'),
        ),
      );
      return;
    }

    if (horaSaida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a hora de saída.'),
        ),
      );
      return;
    }

    if (dataChegada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data de chegada.'),
        ),
      );
      return;
    }

    if (horaChegada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a hora de chegada.'),
        ),
      );
      return;
    }

    final kmInicial = double.tryParse(
      kmInicialController.text.trim().replaceAll(',', '.'),
    );

    final kmFinal = double.tryParse(
      kmFinalController.text.trim().replaceAll(',', '.'),
    );

    if (kmInicial == null || kmInicial < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um KM inicial válido.'),
        ),
      );
      return;
    }

    if (kmFinal == null || kmFinal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um KM final válido.'),
        ),
      );
      return;
    }

    if (kmFinal < kmInicial) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O KM final não pode ser menor que o KM inicial.',
          ),
        ),
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final saida = combinarDataHora(
        dataSaida!,
        horaSaida!,
      );

      final chegada = combinarDataHora(
        dataChegada!,
        horaChegada!,
      );

      await FirebaseFirestore.instance
          .collection('diarios_bordo')
          .add({
        // ======================================================
        // INFORMAÇÕES AUTOMÁTICAS
        // ======================================================

        'motorista': widget.motorista,
        'frota': widget.caminhao.frota,
        'placa': widget.caminhao.placa,
        'modelo': widget.caminhao.modelo,

        // ======================================================
        // ORIGEM E DESTINO
        // ======================================================

        'origem': origemController.text.trim(),
        'destino': destinoController.text.trim(),

        // ======================================================
        // SAÍDA
        // ======================================================

        'dataSaida': Timestamp.fromDate(saida),

        // ======================================================
        // KM INICIAL
        // ======================================================

        'kmInicial': kmInicial,

        // ======================================================
        // CHEGADA
        // ======================================================

        'dataChegada': Timestamp.fromDate(chegada),

        // ======================================================
        // KM FINAL
        // ======================================================

        'kmFinal': kmFinal,

        // ======================================================
        // DATA DE CRIAÇÃO
        // ======================================================

        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Diário de bordo salvo com sucesso!',
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
            'Erro ao salvar o diário de bordo: $e',
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
  // LIMPAR
  // ==========================================================

  void limparFormulario() {
    origemController.clear();
    destinoController.clear();
    kmInicialController.clear();
    kmFinalController.clear();

    setState(() {
      dataSaida = null;
      horaSaida = null;
      dataChegada = null;
      horaChegada = null;
    });
  }

  // ==========================================================
  // CAMPO TEXTO
  // ==========================================================

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Informe $label';
          }

          return null;
        },
      ),
    );
  }

  // ==========================================================
  // CAMPO DATA
  // ==========================================================

  Widget campoData({
    required String label,
    required DateTime? data,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_month),
            border: const OutlineInputBorder(),
          ),
          child: Text(
            formatarData(data),
            style: TextStyle(
              fontSize: 16,
              color: data == null
                  ? Colors.grey.shade600
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CAMPO HORA
  // ==========================================================

  Widget campoHora({
    required String label,
    required TimeOfDay? hora,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.access_time),
            border: const OutlineInputBorder(),
          ),
          child: Text(
            formatarHora(hora),
            style: TextStyle(
              fontSize: 16,
              color: hora == null
                  ? Colors.grey.shade600
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // IDENTIFICAÇÃO DO CAMINHÃO
  // ==========================================================

  Widget identificacaoCaminhao() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.local_shipping,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
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
        builder: (_) => HistoricoDiarioBordoPage(
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
          'DIÁRIO DE BORDO',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Histórico',
            onPressed: abrirHistorico,
            icon: const Icon(Icons.history),
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
                      'DIÁRIO DE BORDO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // ORIGEM
                    // ==================================================

                    campoTexto(
                      label: 'Origem',
                      controller: origemController,
                      icon: Icons.trip_origin,
                    ),

                    // ==================================================
                    // DESTINO
                    // ==================================================

                    campoTexto(
                      label: 'Destino',
                      controller: destinoController,
                      icon: Icons.location_on,
                    ),

                    // ==================================================
                    // DATA DE SAÍDA
                    // ==================================================

                    campoData(
                      label: 'Data de saída',
                      data: dataSaida,
                      onTap: selecionarDataSaida,
                    ),

                    // ==================================================
                    // HORA DE SAÍDA
                    // ==================================================

                    campoHora(
                      label: 'Hora de saída',
                      hora: horaSaida,
                      onTap: selecionarHoraSaida,
                    ),

                    // ==================================================
                    // KM INICIAL
                    // ==================================================

                    campoTexto(
                      label: 'KM inicial',
                      controller: kmInicialController,
                      icon: Icons.speed,
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      hint: 'Ex.: 125430',
                    ),

                    // ==================================================
                    // DATA DE CHEGADA
                    // ==================================================

                    campoData(
                      label: 'Data de chegada',
                      data: dataChegada,
                      onTap: selecionarDataChegada,
                    ),

                    // ==================================================
                    // HORA DE CHEGADA
                    // ==================================================

                    campoHora(
                      label: 'Hora de chegada',
                      hora: horaChegada,
                      onTap: selecionarHoraChegada,
                    ),

                    // ==================================================
                    // KM FINAL
                    // ==================================================

                    campoTexto(
                      label: 'KM final',
                      controller: kmFinalController,
                      icon: Icons.speed,
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      hint: 'Ex.: 125780',
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // SALVAR
                    // ==================================================

                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                        salvando ? null : salvarDiario,

                        icon: salvando
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.save),

                        label: Text(
                          salvando
                              ? 'SALVANDO...'
                              : 'SALVAR DIÁRIO DE BORDO',

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // HISTÓRICO
                    // ==================================================

                    OutlinedButton.icon(
                      onPressed: abrirHistorico,
                      icon: const Icon(Icons.history),
                      label: const Text(
                        'VER HISTÓRICO DE DIÁRIOS',
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
// HISTÓRICO DO DIÁRIO DE BORDO
// ============================================================

class HistoricoDiarioBordoPage extends StatelessWidget {
  final String motorista;

  const HistoricoDiarioBordoPage({
    super.key,
    required this.motorista,
  });

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String formatarData(Timestamp? timestamp) {
    if (timestamp == null) {
      return '-';
    }

    final data = timestamp.toDate();

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  // ==========================================================
  // FORMATAR HORA
  // ==========================================================

  String formatarHora(Timestamp? timestamp) {
    if (timestamp == null) {
      return '-';
    }

    final data = timestamp.toDate();

    final hora =
    data.hour.toString().padLeft(2, '0');

    final minuto =
    data.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  // ==========================================================
  // FORMATAR KM
  // ==========================================================

  String formatarKm(dynamic valor) {
    if (valor == null) {
      return '-';
    }

    final numero = double.tryParse(
      valor.toString().replaceAll(',', '.'),
    );

    if (numero == null) {
      return valor.toString();
    }

    if (numero == numero.truncateToDouble()) {
      return numero.toInt().toString();
    }

    return numero.toString();
  }

  // ==========================================================
  // EDITAR
  // ==========================================================

  Future<void> editarDiario(
      BuildContext context,
      String id,
      Map<String, dynamic> dados,
      ) async {
    final origemController = TextEditingController(
      text: dados['origem']?.toString() ?? '',
    );

    final destinoController = TextEditingController(
      text: dados['destino']?.toString() ?? '',
    );

    // ========================================================
    // CORRIGIDO:
    // NÃO MOSTRA .0 NA EDIÇÃO
    // ========================================================

    final kmInicialController =
    TextEditingController(
      text: formatarKm(dados['kmInicial']),
    );

    final kmFinalController =
    TextEditingController(
      text: formatarKm(dados['kmFinal']),
    );

    Timestamp? timestampSaida =
    dados['dataSaida'] is Timestamp
        ? dados['dataSaida'] as Timestamp
        : null;

    Timestamp? timestampChegada =
    dados['dataChegada'] is Timestamp
        ? dados['dataChegada'] as Timestamp
        : null;

    DateTime? dataSaida =
    timestampSaida?.toDate();

    TimeOfDay? horaSaida =
    timestampSaida == null
        ? null
        : TimeOfDay.fromDateTime(
      timestampSaida.toDate(),
    );

    DateTime? dataChegada =
    timestampChegada?.toDate();

    TimeOfDay? horaChegada =
    timestampChegada == null
        ? null
        : TimeOfDay.fromDateTime(
      timestampChegada.toDate(),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool salvandoEdicao = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ==================================================
            // DATA DE SAÍDA
            // ==================================================

            Future<void> escolherDataSaida() async {
              final data = await showDatePicker(
                context: context,
                initialDate:
                dataSaida ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                locale: const Locale('pt', 'BR'),
                helpText: 'DATA DE SAÍDA',
                cancelText: 'CANCELAR',
                confirmText: 'CONFIRMAR',
              );

              if (data != null) {
                setDialogState(() {
                  dataSaida = data;
                });
              }
            }

            // ==================================================
            // HORA DE SAÍDA
            // ==================================================

            Future<void> escolherHoraSaida() async {
              final hora = await showTimePicker(
                context: context,
                initialTime:
                horaSaida ?? TimeOfDay.now(),
                helpText: 'HORA DE SAÍDA',
                cancelText: 'CANCELAR',
                confirmText: 'CONFIRMAR',
              );

              if (hora != null) {
                setDialogState(() {
                  horaSaida = hora;
                });
              }
            }

            // ==================================================
            // DATA DE CHEGADA
            // ==================================================

            Future<void> escolherDataChegada() async {
              final data = await showDatePicker(
                context: context,
                initialDate:
                dataChegada ??
                    dataSaida ??
                    DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                locale: const Locale('pt', 'BR'),
                helpText: 'DATA DE CHEGADA',
                cancelText: 'CANCELAR',
                confirmText: 'CONFIRMAR',
              );

              if (data != null) {
                setDialogState(() {
                  dataChegada = data;
                });
              }
            }

            // ==================================================
            // HORA DE CHEGADA
            // ==================================================

            Future<void> escolherHoraChegada() async {
              final hora = await showTimePicker(
                context: context,
                initialTime:
                horaChegada ?? TimeOfDay.now(),
                helpText: 'HORA DE CHEGADA',
                cancelText: 'CANCELAR',
                confirmText: 'CONFIRMAR',
              );

              if (hora != null) {
                setDialogState(() {
                  horaChegada = hora;
                });
              }
            }

            // ==================================================
            // TEXTO DATA
            // ==================================================

            String textoData(DateTime? data) {
              if (data == null) {
                return 'Selecionar data';
              }

              return '${data.day.toString().padLeft(2, '0')}/'
                  '${data.month.toString().padLeft(2, '0')}/'
                  '${data.year}';
            }

            // ==================================================
            // TEXTO HORA
            // ==================================================

            String textoHora(TimeOfDay? hora) {
              if (hora == null) {
                return 'Selecionar hora';
              }

              return '${hora.hour.toString().padLeft(2, '0')}:'
                  '${hora.minute.toString().padLeft(2, '0')}';
            }

            // ==================================================
            // COMBINAR DATA + HORA
            // ==================================================

            DateTime combinar(
                DateTime data,
                TimeOfDay hora,
                ) {
              return DateTime(
                data.year,
                data.month,
                data.day,
                hora.hour,
                hora.minute,
              );
            }

            // ==================================================
            // SALVAR EDIÇÃO
            // ==================================================

            Future<void> salvarEdicao() async {
              final origem =
              origemController.text.trim();

              final destino =
              destinoController.text.trim();

              final kmInicial = double.tryParse(
                kmInicialController.text
                    .trim()
                    .replaceAll(',', '.'),
              );

              final kmFinal = double.tryParse(
                kmFinalController.text
                    .trim()
                    .replaceAll(',', '.'),
              );

              if (origem.isEmpty ||
                  destino.isEmpty ||
                  dataSaida == null ||
                  horaSaida == null ||
                  dataChegada == null ||
                  horaChegada == null ||
                  kmInicial == null ||
                  kmFinal == null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Preencha todos os campos corretamente.',
                    ),
                  ),
                );
                return;
              }

              if (kmInicial < 0 ||
                  kmFinal < 0) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Informe valores de KM válidos.',
                    ),
                  ),
                );
                return;
              }

              if (kmFinal < kmInicial) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'O KM final não pode ser menor que o KM inicial.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                salvandoEdicao = true;
              });

              try {
                final novaSaida = combinar(
                  dataSaida!,
                  horaSaida!,
                );

                final novaChegada = combinar(
                  dataChegada!,
                  horaChegada!,
                );

                await FirebaseFirestore.instance
                    .collection('diarios_bordo')
                    .doc(id)
                    .update({
                  'origem': origem,
                  'destino': destino,
                  'dataSaida':
                  Timestamp.fromDate(
                    novaSaida,
                  ),
                  'kmInicial': kmInicial,
                  'dataChegada':
                  Timestamp.fromDate(
                    novaChegada,
                  ),
                  'kmFinal': kmFinal,
                  'editadoEm':
                  FieldValue.serverTimestamp(),
                });

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Diário de bordo atualizado com sucesso!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                setDialogState(() {
                  salvandoEdicao = false;
                });

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Erro ao editar: $e',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            // ==================================================
            // JANELA DE EDIÇÃO
            // ==================================================

            return AlertDialog(
              title: const Text(
                'EDITAR DIÁRIO DE BORDO',
              ),

              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ========================================
                      // ORIGEM
                      // ========================================

                      TextFormField(
                        controller:
                        origemController,
                        decoration:
                        const InputDecoration(
                          labelText: 'Origem',
                          prefixIcon:
                          Icon(Icons.trip_origin),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ========================================
                      // DESTINO
                      // ========================================

                      TextFormField(
                        controller:
                        destinoController,
                        decoration:
                        const InputDecoration(
                          labelText: 'Destino',
                          prefixIcon:
                          Icon(Icons.location_on),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ========================================
                      // DATA SAÍDA
                      // ========================================

                      InkWell(
                        onTap:
                        escolherDataSaida,
                        child: InputDecorator(
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Data de saída',
                            prefixIcon:
                            Icon(
                              Icons.calendar_month,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          child: Text(
                            textoData(dataSaida),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ========================================
                      // HORA SAÍDA
                      // ========================================

                      InkWell(
                        onTap:
                        escolherHoraSaida,
                        child: InputDecorator(
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Hora de saída',
                            prefixIcon:
                            Icon(
                              Icons.access_time,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          child: Text(
                            textoHora(horaSaida),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ========================================
                      // KM INICIAL
                      // ========================================

                      TextFormField(
                        controller:
                        kmInicialController,
                        keyboardType:
                        const TextInputType
                            .numberWithOptions(
                          decimal: false,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText: 'KM inicial',
                          prefixIcon:
                          Icon(Icons.speed),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ========================================
                      // DATA CHEGADA
                      // ========================================

                      InkWell(
                        onTap:
                        escolherDataChegada,
                        child: InputDecorator(
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Data de chegada',
                            prefixIcon:
                            Icon(
                              Icons.calendar_month,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          child: Text(
                            textoData(dataChegada),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ========================================
                      // HORA CHEGADA
                      // ========================================

                      InkWell(
                        onTap:
                        escolherHoraChegada,
                        child: InputDecorator(
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Hora de chegada',
                            prefixIcon:
                            Icon(
                              Icons.access_time,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          child: Text(
                            textoHora(horaChegada),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ========================================
                      // KM FINAL
                      // ========================================

                      TextFormField(
                        controller:
                        kmFinalController,
                        keyboardType:
                        const TextInputType
                            .numberWithOptions(
                          decimal: false,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText: 'KM final',
                          prefixIcon:
                          Icon(Icons.speed),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // BOTÕES
              // ==================================================

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
                  const Text('CANCELAR'),
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
    destinoController.dispose();
    kmInicialController.dispose();
    kmFinalController.dispose();
  }

  // ==========================================================
  // BUILD HISTÓRICO
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HISTÓRICO DE DIÁRIOS',
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('diarios_bordo')
            .where(
          'motorista',
          isEqualTo: motorista,
        )
            .orderBy(
          'dataSaida',
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
                          .menu_book_outlined,
                      size: 70,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 15),

                    Text(
                      'Nenhum diário de bordo lançado.',
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

              final origem =
                  dados['origem']
                      ?.toString() ??
                      '-';

              final destino =
                  dados['destino']
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

              // ==================================================
              // KM FORMATADO SEM .0
              // ==================================================

              final kmInicial =
              formatarKm(
                dados['kmInicial'],
              );

              final kmFinal =
              formatarKm(
                dados['kmFinal'],
              );

              final dataSaida =
              dados['dataSaida']
              is Timestamp
                  ? dados['dataSaida']
              as Timestamp
                  : null;

              final dataChegada =
              dados['dataChegada']
              is Timestamp
                  ? dados['dataChegada']
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
                      Icons.menu_book,
                    ),
                  ),

                  title: Text(
                    '$origem → $destino',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    '${formatarData(dataSaida)} • '
                        'KM $kmInicial → $kmFinal',
                  ),

                  trailing:
                  IconButton(
                    tooltip: 'Editar',

                    icon: const Icon(
                      Icons.edit,
                    ),

                    onPressed: () {
                      editarDiario(
                        context,
                        documento.id,
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
                      'Destino',
                      destino,
                    ),

                    _linhaHistorico(
                      'Data saída',
                      formatarData(
                        dataSaida,
                      ),
                    ),

                    _linhaHistorico(
                      'Hora saída',
                      formatarHora(
                        dataSaida,
                      ),
                    ),

                    _linhaHistorico(
                      'KM inicial',
                      kmInicial,
                    ),

                    _linhaHistorico(
                      'Data chegada',
                      formatarData(
                        dataChegada,
                      ),
                    ),

                    _linhaHistorico(
                      'Hora chegada',
                      formatarHora(
                        dataChegada,
                      ),
                    ),

                    _linhaHistorico(
                      'KM final',
                      kmFinal,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Align(
                      alignment:
                      Alignment.centerRight,

                      child:
                      ElevatedButton.icon(
                        onPressed: () {
                          editarDiario(
                            context,
                            documento.id,
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
            width: 120,

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