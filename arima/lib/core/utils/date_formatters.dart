import 'package:intl/intl.dart';

class DateFormatters {
  const DateFormatters._();

  static String shortDateTime(DateTime? value) {
    if (value == null) {
      return 'No deadline';
    }

    return DateFormat('dd MMM, HH:mm').format(value.toLocal());
  }
}
