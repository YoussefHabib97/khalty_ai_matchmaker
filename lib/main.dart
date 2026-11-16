import 'package:flutter/services.dart';
import 'package:khalty_ai_matchmaker/app/app.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await setupServiceLocator();
  runApp(ApplicationRoot(router: getIt(), session: getIt()));
}
