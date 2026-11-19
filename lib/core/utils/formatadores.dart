class Formatadores {
  static String formatarNumero(double valor, {int casasDecimais = 2}) {
    final negativo = valor < 0;
    final absoluto = valor.abs();
    final partes = absoluto.toStringAsFixed(casasDecimais).split('.');
    final inteira = _inserirSeparadorMilhar(partes[0]);
    final prefixo = negativo ? '-' : '';
    if (casasDecimais == 0 || partes.length < 2) {
      return '$prefixo$inteira';
    }
    return '$prefixo$inteira,${partes[1]}';
  }

  static String _inserirSeparadorMilhar(String digitos) {
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      final posicaoDireita = digitos.length - i;
      if (i > 0 && posicaoDireita % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digitos[i]);
    }
    return buffer.toString();
  }

  static String formatarMoeda(double valor) =>
      'R\$ ${formatarNumero(valor, casasDecimais: 2)}';

  static String formatarConsumo(double kmPorLitro) =>
      '${formatarNumero(kmPorLitro, casasDecimais: 2)} km/L';

  static String formatarCustoPorKm(double reaisPorKm) =>
      'R\$ ${formatarNumero(reaisPorKm, casasDecimais: 2)}/km';

  static String formatarLitros(double litros) =>
      '${formatarNumero(litros, casasDecimais: 2)} L';

  static String formatarQuilometragem(double km) {
    final inteiro = km == km.roundToDouble();
    final texto = formatarNumero(km, casasDecimais: inteiro ? 0 : 1);
    return '$texto km';
  }

  static String formatarData(DateTime dataHora) {
    final local = dataHora.toLocal();
    return '${_dois(local.day)}/${_dois(local.month)}/${local.year}';
  }

  static String formatarDataCurta(DateTime dataHora) {
    final local = dataHora.toLocal();
    return '${_dois(local.day)}/${_dois(local.month)}';
  }

  static String formatarHora(DateTime dataHora) {
    final local = dataHora.toLocal();
    return '${_dois(local.hour)}:${_dois(local.minute)}';
  }

  static String formatarDataHora(DateTime dataHora) =>
      '${formatarData(dataHora)} ${formatarHora(dataHora)}';

  static String _dois(int valor) => valor.toString().padLeft(2, '0');

  /// Converte entradas brasileiras ou internacionais (ex.: "5,89", "5.89", "1.250,5").
  static double? converterNumero(String texto) {
    final limpo = texto.trim().replaceAll(' ', '');
    if (limpo.isEmpty) return null;

    String normalizado;
    if (limpo.contains(',') && limpo.contains('.')) {
      // Ex.: "1.250,50" -> ponto como milhar, vírgula como decimal
      normalizado = limpo.replaceAll('.', '').replaceAll(',', '.');
    } else if (limpo.contains(',')) {
      normalizado = limpo.replaceAll(',', '.');
    } else {
      normalizado = limpo;
    }

    final valor = double.tryParse(normalizado);
    if (valor == null || !valor.isFinite) return null;
    return valor;
  }
}
