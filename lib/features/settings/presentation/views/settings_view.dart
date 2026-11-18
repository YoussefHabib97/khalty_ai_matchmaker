import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/account_cubit.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/language_selector.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/theme_switcher_widget.dart';
import 'package:material_ui/material_ui.dart';

/// Settings: language, theme and account. Expects an [AccountCubit] above
/// it. Signing out changes the session and the router returns to Welcome,
/// so no navigation callback.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirmSignOut'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AccountCubit>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _Section(l10n.languageLabel),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LanguageSelector(),
              ),
            ),
            _Section(l10n.settingsAppearance),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
              child: ThemeSwitcherWidget(),
            ),
            const Divider(),
            _Section(l10n.settingsAccount),
            if (state.phoneE164 case final phone?)
              ListTile(
                leading: const Icon(Icons.phone_iphone),
                // Keep the number left-to-right inside Arabic text.
                title: Text(l10n.signedInAs('\u2066$phone\u2069')),
              ),
            // Built with the backend.
            SwitchListTile(
              secondary: const Icon(Icons.pause_circle_outline),
              title: Text(l10n.pauseProfile),
              subtitle: Text(l10n.pauseProfileHint),
              value: false,
              onChanged: null,
            ),
            ListTile(
              key: const Key('signOut'),
              leading: const Icon(Icons.logout),
              title: Text(l10n.signOut),
              enabled: !state.isSigningOut,
              onTap: () => _confirmSignOut(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text(
                l10n.deleteAccount,
                style: TextStyle(color: colors.error),
              ),
              subtitle: Text(l10n.comingSoon),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
    child: Text(
      title,
      style: context.labelLarge.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
