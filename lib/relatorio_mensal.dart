import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'selecao_caminhao.dart';
import 'exportador_relatorio.dart';

// ============================================================
// RELATÓRIO MENSAL
// ============================================================

class RelatorioMensalPage extends StatefulWidget {
const RelatorioMensalPage({super.key});

@override
State<RelatorioMensalPage> createState() =>
_RelatorioMensalPageState();
}

// ============================================================
// MODELO DOS DADOS DE CADA FROTA
// ============================================================

class _DadosFrota {
final Caminhao caminhao;

double toneladas;
double kmRodado;
double faturamento;
double despesas;

_DadosFrota({
required this.caminhao,
this.toneladas = 0,
this.kmRodado = 0,
this.faturamento = 0,
this.despesas = 0,
});

// ==========================================================
// CÁLCULOS
// ==========================================================

double get precoMedioTon {
if (toneladas <= 0) return 0;
return faturamento / toneladas;
}

double get custoMedioTon {
if (toneladas <= 0) return 0;
return despesas / toneladas;
}

double get resultadoTon {
return precoMedioTon - custoMedioTon;
}

double get precoKm {
if (kmRodado <= 0) return 0;
return faturamento / kmRodado;
}

double get custoKm {
if (kmRodado <= 0) return 0;
return despesas / kmRodado;
}
}

// ============================================================
// ESTADO
// ============================================================

class _RelatorioMensalPageState
extends State<RelatorioMensalPage> {
final FirebaseFirestore _firestore =
FirebaseFirestore.instance;

late int _mesSelecionado;
late int _anoSelecionado;

Future<List<_DadosFrota>>? _dadosFuture;

bool _carregandoDespesa = false;

// ==========================================================
// INIT
// ==========================================================

@override
void initState() {
super.initState();

final agora = DateTime.now();

_mesSelecionado = agora.month;
_anoSelecionado = agora.year;

_atualizarDados();
}

// ==========================================================
// ID DO RELATÓRIO
// ==========================================================

String get _idRelatorio {
return '${_anoSelecionado}_'
'${_mesSelecionado.toString().padLeft(2, '0')}';
}

// ==========================================================
// ATUALIZAR DADOS
// ==========================================================

void _atualizarDados() {
_dadosFuture = _buscarDados();
}

// ==========================================================
// TROCAR MÊS
// ==========================================================

void _trocarMes(int? valor) {
if (valor == null) return;

setState(() {
_mesSelecionado = valor;
_atualizarDados();
});
}

// ==========================================================
// TROCAR ANO
// ==========================================================

void _trocarAno(int? valor) {
if (valor == null) return;

setState(() {
_anoSelecionado = valor;
_atualizarDados();
});
}

// ==========================================================
// BUSCAR DADOS
// ==========================================================

Future<List<_DadosFrota>> _buscarDados() async {
// --------------------------------------------------------
// CRIA TODAS AS FROTAS
// --------------------------------------------------------

final mapa = <String, _DadosFrota>{};

for (final caminhao in frotaCaminhoes) {
mapa[caminhao.frota] = _DadosFrota(
caminhao: caminhao,
);
}

// --------------------------------------------------------
// CLIENTES
// --------------------------------------------------------

final clientesSnapshot = await _firestore
    .collection('clientes')
    .get();

final mapaClientes = <String, double>{};

for (final documento in clientesSnapshot.docs) {
final dados = documento.data();

final frete = _numero(
dados['frete'],
);

mapaClientes[documento.id] = frete;
}

// --------------------------------------------------------
// FRETES
// --------------------------------------------------------

final fretesSnapshot = await _firestore
    .collection('fretes')
    .get();

for (final documento in fretesSnapshot.docs) {
final dados = documento.data();

final data = _converterData(
dados['data'],
);

if (data == null) {
continue;
}

if (data.year != _anoSelecionado ||
data.month != _mesSelecionado) {
continue;
}

final frota = dados['frota']
    ?.toString()
    .trim();

if (frota == null || frota.isEmpty) {
continue;
}

final dadosFrota = mapa[frota];

if (dadosFrota == null) {
continue;
}

final peso = _numero(
dados['peso'],
);

final clienteId = dados['clienteId']
    ?.toString();

double valorFrete = 0;

// ------------------------------------------------------
// PRIMEIRO TENTA USAR O FRETE SALVO NO LANÇAMENTO
// ------------------------------------------------------

if (dados['frete'] != null) {
valorFrete = _numero(
dados['frete'],
);
}

if (dados['valorFrete'] != null) {
valorFrete = _numero(
dados['valorFrete'],
);
}

// ------------------------------------------------------
// SE NÃO EXISTIR, USA O VALOR ATUAL DO CLIENTE
// ------------------------------------------------------

if (valorFrete <= 0 &&
clienteId != null &&
clienteId.isNotEmpty) {
valorFrete =
mapaClientes[clienteId] ?? 0;
}

// ------------------------------------------------------
// ACUMULAR TONELADAS
// ------------------------------------------------------

dadosFrota.toneladas += peso;

// ------------------------------------------------------
// ACUMULAR FATURAMENTO
// ------------------------------------------------------

dadosFrota.faturamento +=
peso * valorFrete;
}

// --------------------------------------------------------
// CONTROLE DE KM MENSAL
//
// O KM AGORA VEM DO CONTROLE DIÁRIO DO MOTORISTA.
//
// Cada documento mensal possui:
// - kmInicial
// - ultimoKm
// - kmRodado
//
// O kmRodado é atualizado diariamente pelo motorista,
// portanto o relatório consegue mostrar o KM mesmo antes
// do fechamento do mês.
// --------------------------------------------------------

for (final dadosFrota in mapa.values) {
final documentoId =
'${dadosFrota.caminhao.frota}_$_idRelatorio';

final documento = await _firestore
    .collection('controle_km_mensal')
    .doc(documentoId)
    .get();

if (!documento.exists) {
dadosFrota.kmRodado = 0;
continue;
}

final dados = documento.data();

if (dados == null) {
dadosFrota.kmRodado = 0;
continue;
}

// ------------------------------------------------------
// PRIMEIRO TENTA USAR O KM RODADO JÁ CALCULADO
// ------------------------------------------------------

final kmRodado = _numero(
dados['kmRodado'],
);

if (kmRodado > 0) {
dadosFrota.kmRodado = kmRodado;
continue;
}

// ------------------------------------------------------
// CASO O KM RODADO ESTEJA ZERADO,
// CALCULA PELO KM INICIAL E ÚLTIMO KM
// ------------------------------------------------------

final kmInicial = _numero(
dados['kmInicial'],
);

final ultimoKm = _numero(
dados['ultimoKm'],
);

if (kmInicial > 0 &&
ultimoKm >= kmInicial) {
dadosFrota.kmRodado =
ultimoKm - kmInicial;
} else {
dadosFrota.kmRodado = 0;
}
}

// --------------------------------------------------------
// DESPESAS MANUAIS DO GERENTE
// --------------------------------------------------------

for (final dadosFrota
in mapa.values) {
final documento = await _firestore
    .collection('relatorios_mensais')
    .doc(_idRelatorio)
    .collection('frotas')
    .doc(dadosFrota.caminhao.frota)
    .get();

if (documento.exists) {
final dados =
documento.data();

if (dados != null) {
dadosFrota.despesas =
_numero(dados['despesas']);
}
}
}

// --------------------------------------------------------
// RETORNA AS FROTAS
// --------------------------------------------------------

final resultado = mapa.values.toList();

resultado.sort(
(a, b) => a.caminhao.frota
    .compareTo(b.caminhao.frota),
);

return resultado;
}

// ==========================================================
// CONVERTER NÚMERO
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
// CONVERTER DATA
// ==========================================================

DateTime? _converterData(dynamic valor) {
if (valor == null) {
return null;
}

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
final dia = int.tryParse(
partes[0],
);

final mes = int.tryParse(
partes[1],
);

final ano = int.tryParse(
partes[2],
);

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

// ------------------------------------------------------
// ISO
// ------------------------------------------------------

return DateTime.tryParse(texto);
}

return null;
}

// ==========================================================
// FORMATAR MOEDA
// ==========================================================

String _formatarMoeda(double valor) {
final texto = valor
    .toStringAsFixed(2)
    .replaceAll('.', ',');

return 'R\$ $texto';
}

// ==========================================================
// FORMATAR NÚMERO
// ==========================================================

String _formatarNumero(
double valor, {
int casas = 2,
}) {
return valor
    .toStringAsFixed(casas)
    .replaceAll('.', ',');
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
// EDITAR DESPESA
// ==========================================================

Future<void> _editarDespesa(
_DadosFrota dadosFrota,
) async {
final controller = TextEditingController(
text: dadosFrota.despesas > 0
? dadosFrota.despesas
    .toStringAsFixed(2)
    .replaceAll('.', ',')
    : '',
);

final resultado = await showDialog<double>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: Text(
'Despesas - ${dadosFrota.caminhao.frota}',
),
content: TextField(
controller: controller,
autofocus: true,
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
decoration: const InputDecoration(
labelText: 'Despesas do mês',
hintText: 'Ex.: 15000,00',
prefixText: 'R\$ ',
border: OutlineInputBorder(),
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
ElevatedButton(
onPressed: () {
final valorTexto = controller.text
    .trim()
    .replaceAll('.', '')
    .replaceAll(',', '.');

final valor = double.tryParse(
valorTexto,
);

if (valor == null) {
ScaffoldMessenger.of(
dialogContext,
).showSnackBar(
const SnackBar(
content: Text(
'Informe um valor válido.',
),
),
);

return;
}

Navigator.of(dialogContext).pop(
valor,
);
},
child: const Text(
'SALVAR',
),
),
],
);
},
);

// ----------------------------------------------------------
// IMPORTANTE:
// o diálogo pode ainda estar sendo desmontado neste momento.
// Por isso o controller só será destruído na próxima frame.
// ----------------------------------------------------------

WidgetsBinding.instance.addPostFrameCallback((_) {
controller.dispose();
});

if (resultado == null) {
return;
}

setState(() {
_carregandoDespesa = true;
});

try {
await _firestore
    .collection('relatorios_mensais')
    .doc(_idRelatorio)
    .collection('frotas')
    .doc(dadosFrota.caminhao.frota)
    .set(
{
'frota': dadosFrota.caminhao.frota,
'placa': dadosFrota.caminhao.placa,
'modelo': dadosFrota.caminhao.modelo,
'mes': _mesSelecionado,
'ano': _anoSelecionado,
'despesas': resultado,
'atualizadoEm':
FieldValue.serverTimestamp(),
},
SetOptions(
merge: true,
),
);

if (!mounted) {
return;
}

setState(() {
dadosFrota.despesas = resultado;
_carregandoDespesa = false;
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Despesa salva com sucesso.',
),
backgroundColor: Colors.green,
),
);
} catch (e) {
if (!mounted) {
return;
}

setState(() {
_carregandoDespesa = false;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Erro ao salvar despesa: $e',
),
backgroundColor: Colors.red,
),
);
}
}

// ==========================================================
// CAMPO DE RESULTADO
// ==========================================================

Widget _campoResultado(
String titulo,
String valor, {
bool moeda = false,
}) {
return Expanded(
child: Container(
margin: const EdgeInsets.all(4),
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.grey.shade100,
borderRadius:
BorderRadius.circular(10),
border: Border.all(
color: Colors.grey.shade300,
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
titulo,
style: const TextStyle(
fontSize: 11,
color: Colors.grey,
fontWeight:
FontWeight.w600,
),
),
const SizedBox(height: 4),
Text(
moeda ? 'R\$ $valor' : valor,
style: const TextStyle(
fontSize: 14,
fontWeight:
FontWeight.bold,
),
),
],
),
),
);
}

// ==========================================================
// CARD DA FROTA
// ==========================================================

Widget _cardFrota(
_DadosFrota dadosFrota,
) {
final caminhao =
dadosFrota.caminhao;

return Card(
margin: const EdgeInsets.only(
bottom: 16,
),
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(16),
),
child: Padding(
padding: const EdgeInsets.all(18),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// --------------------------------------------------
// CABEÇALHO
// --------------------------------------------------

Row(
children: [
CircleAvatar(
radius: 24,
child: const Icon(
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
caminhao.frota,
style:
const TextStyle(
fontSize: 19,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 3),
Text(
'${caminhao.placa} • ${caminhao.modelo}',
style:
const TextStyle(
fontSize: 13,
color: Colors.grey,
),
),
],
),
),
IconButton(
tooltip:
'Editar despesas',
onPressed:
_carregandoDespesa
? null
    : () => _editarDespesa(
dadosFrota,
),
icon: const Icon(
Icons.edit,
),
),
],
),

const SizedBox(height: 18),

// --------------------------------------------------
// DADOS PRINCIPAIS
// --------------------------------------------------

Row(
children: [
_campoResultado(
'Ton. Transp.',
_formatarNumero(
dadosFrota.toneladas,
),
),
_campoResultado(
'Km Rodado',
_formatarNumero(
dadosFrota.kmRodado,
casas: 0,
),
),
],
),

Row(
children: [
_campoResultado(
'Faturamento',
_formatarMoeda(
dadosFrota.faturamento,
),
),
_campoResultado(
'Despesas',
_formatarMoeda(
dadosFrota.despesas,
),
),
],
),

const SizedBox(height: 8),

const Divider(),

const SizedBox(height: 8),

// --------------------------------------------------
// INDICADORES
// --------------------------------------------------

Row(
children: [
_campoResultado(
'Preço Méd./Ton.',
_formatarNumero(
dadosFrota.precoMedioTon,
),
moeda: true,
),
_campoResultado(
'Custo Méd./Ton.',
_formatarNumero(
dadosFrota.custoMedioTon,
),
moeda: true,
),
],
),

Row(
children: [
_campoResultado(
'Resultado/Ton.',
_formatarNumero(
dadosFrota.resultadoTon,
),
moeda: true,
),
_campoResultado(
'Preço/KM',
_formatarNumero(
dadosFrota.precoKm,
),
moeda: true,
),
],
),

Row(
children: [
_campoResultado(
'Custo/KM',
_formatarNumero(
dadosFrota.custoKm,
),
moeda: true,
),
const Expanded(
child: SizedBox(),
),
],
),

const SizedBox(height: 8),

// --------------------------------------------------
// AVISO DE DESPESAS
// --------------------------------------------------

if (dadosFrota.despesas <= 0)
Container(
width: double.infinity,
padding:
const EdgeInsets.all(10),
decoration:
BoxDecoration(
color:
Colors.orange.shade50,
borderRadius:
BorderRadius.circular(10),
border: Border.all(
color:
Colors.orange.shade200,
),
),
child: const Row(
children: [
Icon(
Icons.info_outline,
size: 18,
color: Colors.orange,
),
SizedBox(width: 8),
Expanded(
child: Text(
'Despesas ainda não informadas. '
'Clique no lápis para lançar.',
style: TextStyle(
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
);
}

// ==========================================================
// TOTAL GERAL
// ==========================================================

Widget _cardTotal(
List<_DadosFrota> dados,
) {
double toneladas = 0;
double km = 0;
double faturamento = 0;
double despesas = 0;

for (final item in dados) {
toneladas += item.toneladas;
km += item.kmRodado;
faturamento += item.faturamento;
despesas += item.despesas;
}

final double precoMedio =
toneladas > 0
? faturamento / toneladas
    : 0.0;

final double custoMedio =
toneladas > 0
? despesas / toneladas
    : 0.0;

final double resultado =
precoMedio - custoMedio;

final double precoKm =
km > 0
? faturamento / km
    : 0.0;

final double custoKm =
km > 0
? despesas / km
    : 0.0;

return Card(
color: Colors.blueGrey.shade50,
margin: const EdgeInsets.only(
bottom: 20,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(16),
side: BorderSide(
color: Colors.blueGrey
    .shade100,
),
),
child: Padding(
padding: const EdgeInsets.all(18),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'TOTAL DO MÊS',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 15),

Row(
children: [
_campoResultado(
'Toneladas',
_formatarNumero(
toneladas,
),
),
_campoResultado(
'Km Rodado',
_formatarNumero(
km,
casas: 0,
),
),
],
),

Row(
children: [
_campoResultado(
'Faturamento',
_formatarMoeda(
faturamento,
),
),
_campoResultado(
'Despesas',
_formatarMoeda(
despesas,
),
),
],
),

Row(
children: [
_campoResultado(
'Preço Méd./Ton.',
_formatarNumero(
precoMedio,
),
moeda: true,
),
_campoResultado(
'Custo Méd./Ton.',
_formatarNumero(
custoMedio,
),
moeda: true,
),
],
),

Row(
children: [
_campoResultado(
'Resultado/Ton.',
_formatarNumero(
resultado,
),
moeda: true,
),
_campoResultado(
'Preço/KM',
_formatarNumero(
precoKm,
),
moeda: true,
),
],
),

Row(
children: [
_campoResultado(
'Custo/KM',
_formatarNumero(
custoKm,
),
moeda: true,
),
const Expanded(
child: SizedBox(),
),
],
),
],
),
),
);
}

// ==========================================================
// EXPORTAÇÃO
// ==========================================================

List<Map<String, dynamic>> _prepararDadosExportacao(
List<_DadosFrota> dados) {
return dados.map((item) => {
'frota': item.caminhao.frota,
'toneladas': item.toneladas,
'kmRodado': item.kmRodado,
'faturamento': item.faturamento,
'despesas': item.despesas,
}).toList();
}

Future<void> _exportarExcel(List<_DadosFrota> dados) async {
try {
await ExportadorRelatorio.exportarExcel(
mesAno: '${_nomeMes(_mesSelecionado)} de $_anoSelecionado',
dados: _prepararDadosExportacao(dados),
);
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Excel gerado com sucesso.'), backgroundColor: Colors.green),
);
} catch (e) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao gerar Excel: $e'), backgroundColor: Colors.red),
);
}
}

Future<void> _exportarPdf(List<_DadosFrota> dados) async {
try {
await ExportadorRelatorio.exportarPdf(
mesAno: '${_nomeMes(_mesSelecionado)} de $_anoSelecionado',
dados: _prepararDadosExportacao(dados),
);
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('PDF preparado com sucesso.'), backgroundColor: Colors.green),
);
} catch (e) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
);
}
}

// ==========================================================
// BUILD
// ==========================================================

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'RELATÓRIO MENSAL',
),
centerTitle: true,
actions: [
IconButton(
tooltip: 'Atualizar',
onPressed: () {
setState(() {
_atualizarDados();
});
},
icon: const Icon(
Icons.refresh,
),
),
],
),
body: SafeArea(
child: Column(
children: [
// ==================================================
// FILTROS
// ==================================================

Card(
margin:
const EdgeInsets.fromLTRB(
16,
16,
16,
10,
),
child: Padding(
padding:
const EdgeInsets.all(16),
child: Row(
children: [
Expanded(
child:
DropdownButtonFormField<
int>(
initialValue:
_mesSelecionado,
decoration:
const InputDecoration(
labelText:
'Mês',
border:
OutlineInputBorder(),
),
items: List.generate(
12,
(index) {
final mes =
index + 1;

return DropdownMenuItem<
int>(
value: mes,
child: Text(
_nomeMes(mes),
),
);
},
),
onChanged:
_trocarMes,
),
),

const SizedBox(
width: 12,
),

Expanded(
child:
DropdownButtonFormField<
int>(
initialValue:
_anoSelecionado,
decoration:
const InputDecoration(
labelText:
'Ano',
border:
OutlineInputBorder(),
),
items: List.generate(
8,
(index) {
final ano =
DateTime.now()
    .year -
2 +
index;

return DropdownMenuItem<
int>(
value: ano,
child: Text(
ano.toString(),
),
);
},
),
onChanged:
_trocarAno,
),
),
],
),
),
),

// ==================================================
// CONTEÚDO
// ==================================================

Expanded(
child: FutureBuilder<
List<_DadosFrota>>(
future: _dadosFuture,
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
const EdgeInsets.all(
25,
),
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
size: 60,
color: Colors.red,
),
const SizedBox(
height: 15,
),
const Text(
'Erro ao carregar o relatório.',
textAlign:
TextAlign.center,
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
Text(
'${snapshot.error}',
textAlign:
TextAlign.center,
style:
const TextStyle(
fontSize: 12,
),
),
const SizedBox(
height: 20,
),
ElevatedButton.icon(
onPressed: () {
setState(() {
_atualizarDados();
});
},
icon:
const Icon(
Icons.refresh,
),
label:
const Text(
'TENTAR NOVAMENTE',
),
),
],
),
),
);
}

final dados =
snapshot.data ??
[];

if (dados.isEmpty) {
return const Center(
child: Text(
'Nenhum dado encontrado.',
),
);
}

return RefreshIndicator(
onRefresh: () async {
setState(() {
_atualizarDados();
});

await _dadosFuture;
},
child: ListView(
padding:
const EdgeInsets.fromLTRB(
16,
8,
16,
30,
),
children: [
// ------------------------------------------------
// TÍTULO DO PERÍODO
// ------------------------------------------------

Padding(
padding:
const EdgeInsets.only(
bottom: 14,
),
child: Text(
'${_nomeMes(_mesSelecionado)} '
'de $_anoSelecionado',
style:
const TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
),

Row(
children: [
Expanded(
child: ElevatedButton.icon(
onPressed: () => _exportarExcel(dados),
icon: const Icon(Icons.table_chart),
label: const Text('EXPORTAR EXCEL'),
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 13),
),
),
),
const SizedBox(width: 10),
Expanded(
child: ElevatedButton.icon(
onPressed: () => _exportarPdf(dados),
icon: const Icon(Icons.picture_as_pdf),
label: const Text('EXPORTAR PDF'),
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 13),
),
),
),
],
),
const SizedBox(height: 18),

// ------------------------------------------------
// TOTAL
// ------------------------------------------------

_cardTotal(dados),

// ------------------------------------------------
// FROTAS
// ------------------------------------------------

...dados.map(
(item) =>
_cardFrota(item),
),
],
),
);
},
),
),
],
),
),
);
}
}