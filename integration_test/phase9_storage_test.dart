import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/astronomy.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 9 actual SQLite v2 upgrade and old/new SI trial decoding', (
    t,
  ) async {
    final baseline = LocalNotebook();
    await baseline.initialize();
    expect(baseline.recoveryMessage, isNull);
    final original = baseline.trials.first;
    final path =
        '${await getDatabasesPath()}/phase9-migration-${DateTime.now().microsecondsSinceEpoch}.db';
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
          'note': 'Phase 9 retained migration fixture',
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
      'Phase 9 retained migration fixture',
    );
    expect((await migrated.readSession(original.labId))!['parameters'], {
      'reference': 2.5,
    });
    final extra = Trial(
      id: 'phase9-storage-fixture',
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
      'Phase 9 retained migration fixture',
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
    final checks = <String, dynamic>{};
    for (final version in [1, 3]) {
      final fixturePath =
          '${await getDatabasesPath()}/phase9-integrity-$version-${DateTime.now().microsecondsSinceEpoch}.db';
      if (version == 1) {
        final legacy = await openDatabase(
          fixturePath,
          version: 1,
          onCreate: (db, v) async {
            await db.execute(
              'CREATE TABLE trials(id TEXT PRIMARY KEY,body TEXT NOT NULL)',
            );
          },
        );
        await legacy.insert('trials', {'id': original.id, 'body': body});
        await legacy.close();
      }
      final repo = LocalNotebook(databasePath: fixturePath);
      await repo.initialize();
      expect(repo.trials.length, version == 1 ? 1 : 0);
      final fixture = await openDatabase(fixturePath);
      // Simulate a failed write transaction and check rollback, not a destructive process kill.
      try {
        await fixture.transaction((txn) async {
          await txn.insert('sessions', {
            'id': 'interrupted',
            'body': 'partial',
          });
          throw StateError('Deliberate fixture rollback');
        });
      } catch (_) {}
      expect(
        await fixture.query(
          'sessions',
          where: 'id=?',
          whereArgs: ['interrupted'],
        ),
        isEmpty,
      );
      await fixture.insert('trials', {'id': 'malformed', 'body': '{broken'});
      await fixture.insert('sessions', {
        'id': 's01-e00',
        'body': '{unreadable',
      });
      expect((await repo.readTrials()).length, version == 1 ? 1 : 0);
      expect(await repo.readSession('s01-e00'), isNull);
      final retained = (await repo.savedSessionIds())
          .where((k) => k.startsWith('backup:s01-e00:'))
          .single;
      expect(
        (await repo.readSession(retained))!['original']['unreadableRaw'],
        '{unreadable',
      );
      expect(
        (await fixture.query(
          'trials',
          where: 'id=?',
          whereArgs: ['malformed'],
        )).single['body'],
        '{broken',
      );
      expect(
        (await fixture.rawQuery('PRAGMA integrity_check')).single.values.single,
        'ok',
      );
      final batch = fixture.batch();
      for (int i = 0; i < 500; i++) {
        final copy = original.toJson()
          ..['id'] = 'isolated-stress-$i'
          ..['note'] =
              'Phase9 isolated database stress fixture: copy of a calculated reference trial';
        batch.insert('trials', {
          'id': 'isolated-stress-$i',
          'body': jsonEncode(copy),
        });
      }
      await batch.commit(noResult: true);
      final readWatch = Stopwatch()..start();
      final history = await repo.readTrials();
      readWatch.stop();
      expect(history.length, version == 1 ? 501 : 500);
      expect(csvEncode(history), contains('isolated-stress-499'));
      checks['schema$version'] = {
        'freshOrUpgrade': true,
        'validStressTrials': history.length,
        'historyReadMs': readWatch.elapsedMicroseconds / 1000,
        'transactionRollback': true,
        'malformedTrialRetained': true,
        'malformedSessionBackedUp': true,
      };
      await fixture.close();
    }
    binding.reportData ??= {};
    binding.reportData!.addAll({
      'phase9Storage': {
        'actualV2toV3Upgrade': true,
        'additionalNativeFixtures': checks,
        'comparisonAndMasteryRoundTrip': true,
        'documentedDefaultsBackupRetained': true,
        'oldTrialBodyUnchanged': true,
        'oldSessionNoteAndParametersRetained': true,
        'newAstronomySITrialRoundTrip': true,
        'mainDatabaseOriginalTrials': baseline.trials.length,
        'mainDatabaseRecoveryMessage': baseline.recoveryMessage,
      },
    });
  });
}
