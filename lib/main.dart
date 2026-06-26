import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'presentation/writeflow_app.dart';

export 'presentation/writeflow_app.dart' show WriteFlowApp;

void main() {
  runApp(WriteFlowApp(dependencies: AppDependencies.production()));
}
