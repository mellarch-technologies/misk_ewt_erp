class CurrencyHelper {
  // Formats a number in Indian numbering system with short-hands.
  // Examples: 1500 -> ₹1,500; 125000 -> ₹1.25 Lakh; 25000000 -> ₹2.5 Cr
  static String formatInr(num? amount, {bool shortHand = true, String symbol = '₹'}) {
    if (amount == null) return '${symbol}0';
    final n = amount.toDouble();
    if (shortHand) {
      if (n >= 1e7) {
        final v = (n / 1e7);
        return '$symbol${_trim(v)} Cr';
      } else if (n >= 1e5) {
        final v = (n / 1e5);
        return '$symbol${_trim(v)} Lakh';
      }
    }
    return '$symbol${_indianGrouping(n)}';
  }

  static String _trim(double v) {
    // Keep up to 2 decimals, trim trailing zeros
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.00$'), '').replaceFirst(RegExp(r'0$'), '');
  }

  static String _indianGrouping(double n) {
    final s = n.toStringAsFixed(0);
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    String rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    while (rest.length > 2) {
      final chunk = rest.substring(rest.length - 2);
      rest = rest.substring(0, rest.length - 2);
      buf.write(',$chunk');
    }
    if (rest.isNotEmpty) buf.write(',$rest');
    final prefix = buf.toString().split('').reversed.join('');
    final cleaned = prefix.startsWith(',') ? prefix.substring(1) : prefix;
    return '${cleaned.split('').reversed.join('')},$last3';
  }
}

