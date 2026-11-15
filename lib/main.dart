import 'package:flutter/services.dart';
import 'package:khalty_ai_matchmaker/app.dart';
import 'package:khalty_ai_matchmaker/core/helpers/shared_preferences.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SharedPrefs.init();
  runApp(ApplicationRoot());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Khalty', home: ApplicationRoot());
  }
}
