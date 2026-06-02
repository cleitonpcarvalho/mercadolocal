import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  static String currency(num value) => _currency.format(value);

  static String date(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String dateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String relativeTime(DateTime? date) {
    if (date == null) return '-';

    final Duration diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }
}
