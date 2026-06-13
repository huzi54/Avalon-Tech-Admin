import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en', 'CA'),
    Locale('fr', 'CA'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en', 'CA'));
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'settings': 'Settings',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'language': 'Language',
      'english': 'English',
      'frenchCanada': 'French (Canada)',
      'support': 'Support',
      'contactSupport': 'Contact Support',
      'supportDescription': 'Get help with your account or payroll app.',
      'logout': 'Logout',
      'ownerDashboard': 'Owner Dashboard',
      'dashboard': 'Dashboard',
      'employees': 'Employees',
      'payroll': 'Payroll',
      'remittance': 'Remittance',
      'subscription': 'Subscription',
      'subscriptionManagedByAdmin':
          'Your subscription is managed by the platform administrator.',
      'preferencesSaved': 'Preferences are saved on this device.',
    },
    'fr': {
      'settings': 'Paramètres',
      'appearance': 'Apparence',
      'theme': 'Thème',
      'light': 'Clair',
      'dark': 'Sombre',
      'system': 'Système',
      'language': 'Langue',
      'english': 'Anglais',
      'frenchCanada': 'Français (Canada)',
      'support': 'Soutien',
      'contactSupport': 'Communiquer avec le soutien',
      'supportDescription':
          'Obtenez de l’aide pour votre compte ou l’application de paie.',
      'logout': 'Déconnexion',
      'ownerDashboard': 'Tableau de bord du propriétaire',
      'dashboard': 'Tableau de bord',
      'employees': 'Employés',
      'payroll': 'Paie',
      'remittance': 'Versements',
      'subscription': 'Abonnement',
      'subscriptionManagedByAdmin':
          'Votre abonnement est géré par l’administrateur de la plateforme.',
      'preferencesSaved': 'Les préférences sont enregistrées sur cet appareil.',
    },
  };

  String text(String key) {
    return _values[locale.languageCode]?[key] ?? _values['en']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  String tr(String key) => AppLocalizations.of(this).text(key);
}
