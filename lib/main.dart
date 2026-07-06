import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'presentation/inkdoc_app.dart';

export 'presentation/inkdoc_app.dart' show InkDocApp;

void main() {
  runApp(InkDocApp(dependencies: AppDependencies.production()));
}
