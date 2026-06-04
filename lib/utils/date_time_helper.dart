import 'package:intl/intl.dart';

class DateTimeHelper {
  const DateTimeHelper._();

  static String formatDate(DateTime value) => DateFormat.yMMMd().format(value);

  static String formatDateTime(DateTime value) {
    return DateFormat.yMMMd().add_jm().format(value);
  }

  static String currency(num value) =>
      NumberFormat.simpleCurrency().format(value);
}
