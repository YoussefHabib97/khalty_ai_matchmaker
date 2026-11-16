import 'package:flutter/services.dart';
import 'package:khalty_ai_matchmaker/app/app.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SharedPrefs.init();
  runApp(ApplicationRoot());
}
