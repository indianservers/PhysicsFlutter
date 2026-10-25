import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/persistence/notebook.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notebook = LocalNotebook();
  await notebook.initialize();
  runApp(
    ProviderScope(
      overrides: [notebookProvider.overrideWithValue(notebook)],
      child: const PhysicsApp(),
    ),
  );
}
