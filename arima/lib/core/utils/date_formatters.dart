import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

class DateFormatters {
  const DateFormatters._();

  static String shortDateTime(DateTime? value, {AppLocalizations? l10n}) {
    if (value == null) {
      return l10n?.noDeadlineValue() ?? 'No deadline';
    }

    return DateFormat(
      'dd MMM, HH:mm',
      l10n?.locale.languageCode,
    ).format(value.toLocal());
  }
}
