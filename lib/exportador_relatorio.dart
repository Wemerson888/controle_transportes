import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportadorRelatorio {
  static Future<void> exportarExcel({
    required String mesAno,
    required List<Map<String, dynamic>> dados,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Relatório'];

    final tituloStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cabecalhoStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#455A64'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final textoStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final numeroStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: NumFormat.standard_2,
    );

    final inteiroStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: NumFormat.standard_3,
    );

    final moedaStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: NumFormat.standard_44,
    );

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('J1'),
      customValue: TextCellValue('RELATÓRIO DE TRANSPORTES'),
    );
    sheet.setMergedCellStyle(CellIndex.indexByString('A1'), tituloStyle);
    sheet.setRowHeight(0, 30);

    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('J2'),
      customValue: TextCellValue(mesAno),
    );
    sheet.setMergedCellStyle(
      CellIndex.indexByString('A2'),
      CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      ),
    );

    const cabecalhos = [
      'FROTAS',
      'Ton. Transp.',
      'Km Rodado',
      'Faturamento',
      'Despesas',
      'Preço Méd./Ton.',
      'Custo Méd./Ton.',
      'Resultado/Ton.',
      'Preço/KM',
      'Custo/KM',
    ];

    for (var coluna = 0; coluna < cabecalhos.length; coluna++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: coluna, rowIndex: 3),
        TextCellValue(cabecalhos[coluna]),
        cellStyle: cabecalhoStyle,
      );
    }

    for (var i = 0; i < dados.length; i++) {
      final item = dados[i];
      final row = i + 4;
      final toneladas = _toDouble(item['toneladas']);
      final km = _toDouble(item['kmRodado']);
      final faturamento = _toDouble(item['faturamento']);
      final despesas = _toDouble(item['despesas']);
      final precoMedio = toneladas > 0 ? faturamento / toneladas : 0.0;
      final custoMedio = toneladas > 0 ? despesas / toneladas : 0.0;
      final resultado = precoMedio - custoMedio;
      final precoKm = km > 0 ? faturamento / km : 0.0;
      final custoKm = km > 0 ? despesas / km : 0.0;

      _texto(sheet, 0, row, item['frota']?.toString() ?? '', textoStyle);
      _numeroCelula(sheet, 1, row, toneladas, numeroStyle);
      _numeroCelula(sheet, 2, row, km, inteiroStyle);
      _numeroCelula(sheet, 3, row, faturamento, moedaStyle);
      _numeroCelula(sheet, 4, row, despesas, moedaStyle);
      _numeroCelula(sheet, 5, row, precoMedio, moedaStyle);
      _numeroCelula(sheet, 6, row, custoMedio, moedaStyle);
      _numeroCelula(sheet, 7, row, resultado, moedaStyle);
      _numeroCelula(sheet, 8, row, precoKm, moedaStyle);
      _numeroCelula(sheet, 9, row, custoKm, moedaStyle);
    }

    double totalToneladas = 0;
    double totalKm = 0;
    double totalFaturamento = 0;
    double totalDespesas = 0;
    for (final item in dados) {
      totalToneladas += _toDouble(item['toneladas']);
      totalKm += _toDouble(item['kmRodado']);
      totalFaturamento += _toDouble(item['faturamento']);
      totalDespesas += _toDouble(item['despesas']);
    }

    final totalPrecoMedio = totalToneladas > 0 ? totalFaturamento / totalToneladas : 0.0;
    final totalCustoMedio = totalToneladas > 0 ? totalDespesas / totalToneladas : 0.0;
    final totalResultado = totalPrecoMedio - totalCustoMedio;
    final totalPrecoKm = totalKm > 0 ? totalFaturamento / totalKm : 0.0;
    final totalCustoKm = totalKm > 0 ? totalDespesas / totalKm : 0.0;
    final totalRow = dados.length + 4;

    final totalBase = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#ECEFF1'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final totalNumero = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#ECEFF1'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: NumFormat.standard_2,
    );
    final totalInteiro = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#ECEFF1'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: NumFormat.standard_3,
    );
    final totalMoeda = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#ECEFF1'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: NumFormat.standard_44,
    );

    _texto(sheet, 0, totalRow, 'TOTAL', totalBase.copyWith(horizontalAlignVal: HorizontalAlign.Center));
    _numeroCelula(sheet, 1, totalRow, totalToneladas, totalNumero);
    _numeroCelula(sheet, 2, totalRow, totalKm, totalInteiro);
    _numeroCelula(sheet, 3, totalRow, totalFaturamento, totalMoeda);
    _numeroCelula(sheet, 4, totalRow, totalDespesas, totalMoeda);
    _numeroCelula(sheet, 5, totalRow, totalPrecoMedio, totalMoeda);
    _numeroCelula(sheet, 6, totalRow, totalCustoMedio, totalMoeda);
    _numeroCelula(sheet, 7, totalRow, totalResultado, totalMoeda);
    _numeroCelula(sheet, 8, totalRow, totalPrecoKm, totalMoeda);
    _numeroCelula(sheet, 9, totalRow, totalCustoKm, totalMoeda);

    sheet.setAutoFilter(
      CellIndex.indexByString('A4'),
      CellIndex.indexByString('J${totalRow + 1}'),
    );
    sheet.freezePanes(rows: 4);

    const larguras = [14.0, 15.0, 14.0, 17.0, 17.0, 18.0, 18.0, 18.0, 14.0, 14.0];
    for (var i = 0; i < larguras.length; i++) {
      sheet.setColumnWidth(i, larguras[i]);
    }

    excel.save(
      fileName: 'RELATORIO_TRANSPORTES_${mesAno.replaceAll('/', '-').replaceAll(' ', '_')}.xlsx',
    );
  }

  static Future<void> exportarPdf({
    required String mesAno,
    required List<Map<String, dynamic>> dados,
  }) async {
    final pdf = pw.Document();
    double totalToneladas = 0;
    double totalKm = 0;
    double totalFaturamento = 0;
    double totalDespesas = 0;

    for (final item in dados) {
      totalToneladas += _toDouble(item['toneladas']);
      totalKm += _toDouble(item['kmRodado']);
      totalFaturamento += _toDouble(item['faturamento']);
      totalDespesas += _toDouble(item['despesas']);
    }

    final totalPrecoMedio = totalToneladas > 0 ? totalFaturamento / totalToneladas : 0.0;
    final totalCustoMedio = totalToneladas > 0 ? totalDespesas / totalToneladas : 0.0;
    final totalResultado = totalPrecoMedio - totalCustoMedio;
    final totalPrecoKm = totalKm > 0 ? totalFaturamento / totalKm : 0.0;
    final totalCustoKm = totalKm > 0 ? totalDespesas / totalKm : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final rows = <List<String>>[];
          for (final item in dados) {
            final toneladas = _toDouble(item['toneladas']);
            final km = _toDouble(item['kmRodado']);
            final faturamento = _toDouble(item['faturamento']);
            final despesas = _toDouble(item['despesas']);
            final precoMedio = toneladas > 0 ? faturamento / toneladas : 0.0;
            final custoMedio = toneladas > 0 ? despesas / toneladas : 0.0;
            final resultado = precoMedio - custoMedio;
            final precoKm = km > 0 ? faturamento / km : 0.0;
            final custoKm = km > 0 ? despesas / km : 0.0;

            rows.add([
              item['frota']?.toString() ?? '',
              _formatarNumero(toneladas),
              _formatarNumero(km, casas: 0),
              _moeda(faturamento),
              _moeda(despesas),
              _moeda(precoMedio),
              _moeda(custoMedio),
              _moeda(resultado),
              _moeda(precoKm),
              _moeda(custoKm),
            ]);
          }

          rows.add([
            'TOTAL',
            _formatarNumero(totalToneladas),
            _formatarNumero(totalKm, casas: 0),
            _moeda(totalFaturamento),
            _moeda(totalDespesas),
            _moeda(totalPrecoMedio),
            _moeda(totalCustoMedio),
            _moeda(totalResultado),
            _moeda(totalPrecoKm),
            _moeda(totalCustoKm),
          ]);

          return [
            pw.Text(
              'RELATÓRIO DE TRANSPORTES',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(mesAno, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const [
                'FROTAS', 'Ton. Transp.', 'Km Rodado', 'Faturamento', 'Despesas',
                'Preço Méd./Ton.', 'Custo Méd./Ton.', 'Resultado/Ton.', 'Preço/KM', 'Custo/KM',
              ],
              data: rows,
              headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'RELATORIO_TRANSPORTES_${mesAno.replaceAll('/', '-').replaceAll(' ', '_')}.pdf',
    );
  }

  static void _texto(Sheet sheet, int coluna, int linha, String valor, CellStyle style) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: coluna, rowIndex: linha),
      TextCellValue(valor),
      cellStyle: style,
    );
  }

  static void _numeroCelula(Sheet sheet, int coluna, int linha, double valor, CellStyle style) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: coluna, rowIndex: linha),
      DoubleCellValue(valor),
      cellStyle: style,
    );
  }

  static double _toDouble(dynamic valor) {
    if (valor == null) return 0;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  static String _formatarNumero(double valor, {int casas = 2}) =>
      valor.toStringAsFixed(casas).replaceAll('.', ',');

  static String _moeda(double valor) => 'R\$ ${_formatarNumero(valor)}';
}
