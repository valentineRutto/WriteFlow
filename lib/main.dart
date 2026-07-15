import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'app/app_dependencies.dart';
import 'presentation/inkdoc_app.dart';

export 'presentation/inkdoc_app.dart' show InkDocApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  runApp(InkDocApp(dependencies: AppDependencies.production()));
}
