import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/fluid_modern.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 7 actual SQLite v2 upgrade and old/new SI trial decoding', (
    t,
  ) async {
    final baseline = LocalNotebook();
    await baseline.initialize();
    expect(baseline.recoveryMessage, isNull);
    final original = baseline.trials.first;
    final path =
        '${await getDatabasesPath()}/phase7-migration-${DateTime.now().microsecondsSinceEpoch}.db';
    final old = await openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await db.execute(
          'CREATE TABLE trials(id TEXT PRIMARY KEY,body TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE sessions(id TEXT PRIMARY KEY,body TEXT NOT NULL)',
        );
      },
    );
    final body = jsonEncode(original.toJson());
    await old.insert('trials', {'id': original.id, 'body': body});
    await old.insert('sessions', {
      'id': original.labId,
      'body': jsonEncode({
        'version': 1,
        'state': {
          'note': 'Phase 7 retained migration fixture',
          'parameters': {'reference': 2.5},
        },
      }),
    });
    await old.close();
    final migrated = LocalNotebook(databasePath: path);
    await migrated.initialize();
    expect(migrated.recoveryMessage, isNull);
    expect(migrated.trials.single.toJson(), original.toJson());
    expect(
      (await migrated.readSession(original.labId))!['note'],
      'Phase 7 retained migration fixture',
    );
    expect((await migrated.readSession(original.labId))!['parameters'], {
      'reference': 2.5,
    });
    final extra = Trial(
      id: 'phase7-storage-fixture',
      labId: 's15-e05',
      quantity: 'activity',
      unit: 'Bq',
      value: decayExpectation(0, 1e6, 0, .25, 0)['expectedActivity']!,
      resolution: null,
      configuration: {'initialN': 1e6, 'seed': 42},
      model: fmVersion,
      note: 'Native SI round trip',
    );
    await migrated.addTrial(extra);
    expect((await migrated.readTrials()).last.toJson(), extra.toJson());
    final db = await openDatabase(path);
    expect(await db.getVersion(), 3);
    expect(
      (await db.query(
        'trials',
        where: 'id=?',
        whereArgs: [original.id],
      )).single['body'],
      body,
    );
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name='challenge_attempts'",
      ),
      isNotEmpty,
    );
    expect(
      (await db.rawQuery('PRAGMA integrity_check')).single.values.single,
      'ok',
    );
    await db.close();
    binding.reportData = {
      'phase7Storage': {
        'actualV2toV3Upgrade': true,
        'oldTrialBodyUnchanged': true,
        'oldSessionNoteAndParametersRetained': true,
        'newActivityTrialRoundTrip': true,
        'mainDatabaseOriginalTrials': baseline.trials.length,
        'mainDatabaseRecoveryMessage': baseline.recoveryMessage,
      },
    };
  });
}
