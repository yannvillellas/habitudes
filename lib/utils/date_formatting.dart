import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatDayOfWeek(BuildContext context, DateTime date) =>
    DateFormat.E(Localizations.localeOf(context).toString()).format(date);
