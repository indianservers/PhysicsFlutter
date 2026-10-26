import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/astronomy.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 8 actual SQLite v2 upgrade and old/new SI trial decoding', (
    t,
  ) async {
    final baseline = LocalNotebook();
    await baseline.initialize();
    expect(baseline.recoveryMessage, isNull);
    final original = baseline.trials.first;
    final path =
        '${await getDatabasesPath()}/phase8-migration-${DateTime.now().microsecondsSinceEpoch}.db';
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
          'note': 'Phase 8 retained migration fixture',
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
      'Phase 8 retained migration fixture',
    );
    expect((await migrated.readSession(original.labId))!['parameters'], {
      'reference': 2.5,
    });
    final extra = Trial(
      id: 'phase8-storage-fixture',
      labId: 's16-e04',
      quantity: 'length',
      unit: 'm',
      value: cosmology(.5, 70, .3)['comovingDistance']!,
      resolution: null,
      configuration: {
        'redshift': .5,
        'h0': 70,
        'omegaMatter': .3,
        'dataset': astroDataset,
      },
      model: astroVersion,
      note: 'Native SI round trip',
    );
    await migrated.addTrial(extra);
    expect((await migrated.readTrials()).last.toJson(), extra.toJson());
    await migrated.saveSession('s00-e04', {
      'model': 'comparisons-8.0',
      'parameters': {'resistance': 10000.0},
      'notes': 'Comparison fixture retained',
    });
    expect(
      (await migrated.readSession('s00-e04'))!['model'],
      'comparisons-8.0',
    );
    await migrated.recordAttempt('s00-e05', {
      'model': 'learning-tools-8.0',
      'challengeId': 'read-vernier-01',
      'answer': .0236,
      'target': .0236,
      'correct': true,
      'unit': 'm',
    });
    expect(
      (await migrated.readAttempts('s00-e05')).single['challengeId'],
      'read-vernier-01',
    );
    await migrated.requestDocumentedDefaults(original.labId);
    expect(await migrated.readSession(original.labId), isNull);
    final backup = (await migrated.savedSessionIds()).singleWhere(
      (id) => id.startsWith('backup:${original.labId}:'),
    );
    expect(
      (await migrated.readSession(backup))!['original']['note'],
      'Phase 8 retained migration fixture',
    );
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
      'phase8Storage': {
        'actualV2toV3Upgrade': true,
        'comparisonAndMasteryRoundTrip': true,
        'documentedDefaultsBackupRetained': true,
        'oldTrialBodyUnchanged': true,
        'oldSessionNoteAndParametersRetained': true,
        'newAstronomySITrialRoundTrip': true,
        'mainDatabaseOriginalTrials': baseline.trials.length,
        'mainDatabaseRecoveryMessage': baseline.recoveryMessage,
      },
    };
  });
}
