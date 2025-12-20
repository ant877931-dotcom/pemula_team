import 'package:intl/intl.dart';

// Extension untuk format double ke Rupiah (Rp)
extension FormatExtensions on double {
  String toIDR() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }
}
