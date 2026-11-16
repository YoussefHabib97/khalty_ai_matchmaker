import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/theme_switcher_widget.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Onboarding View")),
      body: Center(child: DefaultPadding(child: ThemeSwitcherWidget())),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
