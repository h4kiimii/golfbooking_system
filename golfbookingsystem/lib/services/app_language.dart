enum AppLanguage { english, malay }

extension AppLanguageLabel on AppLanguage {
  String get label {
    return switch (this) {
      AppLanguage.english => 'English',
      AppLanguage.malay => 'Bahasa Melayu',
    };
  }
}
