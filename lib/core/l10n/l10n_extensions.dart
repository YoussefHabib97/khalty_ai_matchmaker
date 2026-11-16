import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The app language currently shown.
  AppLanguage get appLanguage =>
      AppLanguage.fromCode(Localizations.localeOf(this).languageCode);
}
