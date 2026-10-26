import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/persistence/notebook.dart';
import 'core/rendering/materials.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notebook = LocalNotebook();
  await notebook.initialize();
  await LabMaterials.initialize();
  runApp(
    ProviderScope(
      overrides: [notebookProvider.overrideWithValue(notebook)],
      child: const PhysicsApp(),
    ),
  );
}
