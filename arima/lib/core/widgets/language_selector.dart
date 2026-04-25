import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale/locale_controller.dart';
import '../l10n/app_localizations.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({
    super.key,
    this.showLabel = true,
    this.padding = const EdgeInsets.all(16),
  });

  final bool showLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    String localeDisplayName(Locale locale) {
      switch (locale.languageCode) {
        case 'en':
          return l10n.languageEnglish;
        case 'ru':
          return l10n.languageRussian;
        default:
          return locale.languageCode;
      }
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          DropdownButton<Locale>(
            value: locale,
            icon: const Icon(Icons.arrow_drop_down),
            elevation: 16,
            style: Theme.of(context).textTheme.bodyMedium,
            underline: Container(
              height: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
            onChanged: (Locale? newValue) {
              if (newValue != null) {
                ref.read(localeControllerProvider.notifier).setLocale(newValue);
              }
            },
            items: AppLocalizations.supportedLocales
                .map<DropdownMenuItem<Locale>>((Locale localeItem) {
              return DropdownMenuItem<Locale>(
                value: localeItem,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(localeDisplayName(localeItem)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
