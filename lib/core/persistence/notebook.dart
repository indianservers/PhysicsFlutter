import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../physics/measurement.dart';
import '../../content/catalog.dart';
import '../physics/dynamics.dart';
import '../physics/advanced.dart';
import '../physics/waves_optics.dart';
import '../physics/electromagnetism.dart';

class Trial {
  final String id, labId, quantity, unit, note, created;
  final double value;
  final double? resolution;
  final Map<String, dynamic> configuration;
  final String model;
  Trial({
    required this.id,
    required this.labId,
    required this.quantity,
    required this.unit,
    required this.value,
    required this.resolution,
    required Map<String, dynamic> configuration,
    this.note = '',
    this.model = modelVersion,
    String? created,
  }) : configuration = Map<String, dynamic>.from(
         jsonDecode(jsonEncode(configuration)),
       ),
       created = created ?? DateTime.now().toUtc().toIso8601String();
  Map<String, dynamic> toJson() => {
    'id': id,
    'labId': labId,
    'quantity': quantity,
    'unit': unit,
    'value': value,
    'resolution': resolution,
    'configuration': configuration,
    'note': note,
    'created': created,
    'model': model,
  };
  factory Trial.fromJson(Map<String, dynamic> m) {
    const units = {
      'length': 'm',
      'radius': 'm',
      'speed': 'm/s',
      'mass': 'kg',
      'time': 's',
      'velocity': 'm/s',
      'acceleration': 'm/s²',
      'force': 'N',
      'torque': 'N·m',
      'momentum': 'kg·m/s',
      'energy': 'J',
      'power': 'W',
      'specificEnergy': 'J/kg',
      'damping': 'kg/s',
      'angularFrequency': 'rad/s',
      'efficiency': '',
      'frequency': 'Hz',
      'angle': '°',
      'vergence': 'm⁻¹',
      'relativeIntensity': '',
      'electricField': 'N/C',
      'magneticField': 'T',
      'voltage': 'V',
      'current': 'A',
      'capacitance': 'F',
    };
    if (!units.containsKey(m['quantity']) ||
        units[m['quantity']] != m['unit'] ||
        !allEntries.any((e) => e.id == m['labId'] && e.interactive)) {
      throw const FormatException('Invalid quantity, unit or lab');
    }
    final value = (m['value'] as num).toDouble();
    final resolution = (m['resolution'] as num?)?.toDouble();
    if (!value.isFinite ||
        (resolution != null && (!resolution.isFinite || resolution < 0)) ||
        ![
          modelVersion,
          dynamicsVersion,
          advancedVersion,
          waveOpticsVersion,
          emVersion,
        ].contains(m['model'])) {
      throw const FormatException('Invalid trial/model');
    }
    return Trial(
      id: m['id'],
      labId: m['labId'],
      quantity: m['quantity'],
      unit: m['unit'],
      value: value,
      resolution: resolution,
      configuration: Map<String, dynamic>.from(m['configuration']),
      note: m['note'] ?? '',
      created: m['created'],
      model: m['model'],
    );
  }
}

abstract class ExperimentRepository {
  Future<List<Trial>> readTrials();
  Future<void> addTrial(Trial trial);
  Future<void> saveSession(String id, Map<String, dynamic> state);
  Future<Map<String, dynamic>?> readSession(String id);
}

class LocalNotebook extends ChangeNotifier implements ExperimentRepository {
  final String? databasePath;
  LocalNotebook({this.databasePath});
  Database? _db;
  late SharedPreferences preferences;
  List<Trial> trials = [];
  String? lastLab;
  Set<String> completed = {};
  bool reducedMotion = false, haptics = false;
  String? recoveryMessage;
  Future<void> initialize() async {
    preferences = await SharedPreferences.getInstance();
    lastLab = preferences.getString('lastLab');
    if (!allEntries.any((e) => e.id == lastLab)) {
      lastLab = null;
    }
    completed = (preferences.getStringList('completed') ?? []).toSet();
    completed = completed.intersection(allEntries.map((e) => e.id).toSet());
    reducedMotion = preferences.getBool('reducedMotion') ?? false;
    haptics = preferences.getBool('haptics') ?? false;
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        _db = await openDatabase(
          databasePath ?? '${await getDatabasesPath()}/physics_notebook.db',
          version: 3,
          onCreate: (db, v) async {
            await db.execute(
              'CREATE TABLE trials(id TEXT PRIMARY KEY, body TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE sessions(id TEXT PRIMARY KEY, body TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE challenge_attempts(id TEXT PRIMARY KEY, lab_id TEXT NOT NULL, body TEXT NOT NULL)',
            );
          },
          onUpgrade: (db, old, v) async {
            if (old < 2) {
              await db.execute(
                'CREATE TABLE IF NOT EXISTS sessions(id TEXT PRIMARY KEY, body TEXT NOT NULL)',
              );
            }
            if (old < 3) {
              await db.execute(
                'CREATE TABLE IF NOT EXISTS challenge_attempts(id TEXT PRIMARY KEY, lab_id TEXT NOT NULL, body TEXT NOT NULL)',
              );
            }
          },
        );
      } catch (_) {
        recoveryMessage = 'The database could not be opened. Existing database files are preserved; new work uses local fallback storage.';
      }
    }
    trials = await readTrials();
  }

  @override
  Future<List<Trial>> readTrials() async {
    final List<String> bodies = _db == null
        ? preferences.getStringList('trials') ?? []
        : (await _db!.query('trials')).map((r) => r['body'] as String).toList();
    final valid = <Trial>[];
    for (final body in bodies) {
      try {
        valid.add(Trial.fromJson(jsonDecode(body)));
      } catch (_) {
        recoveryMessage = 'Some incompatible records were skipped. Original stored records were preserved.';
      }
    }
    return valid;
  }

  @override
  Future<void> addTrial(Trial trial) async {
    final body = jsonEncode(trial.toJson());
    if (_db != null) {
      await _db!.insert('trials', {'id': trial.id, 'body': body});
    } else {
      await preferences.setStringList('trials', [
        ...preferences.getStringList('trials') ?? [],
        body,
      ]);
    }
    trials.add(trial);
    notifyListeners();
  }

  @override
  Future<void> saveSession(String id, Map<String, dynamic> state) async {
    final body = jsonEncode({'version': 1, 'state': state});
    if (_db != null) {
      await _db!.insert('sessions', {
        'id': id,
        'body': body,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await preferences.setString('session:$id', body);
    }
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>?> readSession(String id) async {
    try {
      final rows = _db == null
          ? null
          : await _db!.query('sessions', where: 'id = ?', whereArgs: [id]);
      final body = _db == null
          ? preferences.getString('session:$id')
          : rows!.isEmpty
          ? null
          : rows.first['body'] as String;
      if (body == null) {
        return null;
      }
      final m = jsonDecode(body);
      if (m['version'] != 1) {
        throw const FormatException('Session version');
      }
      return Map<String, dynamic>.from(m['state']);
    } catch (_) {
      recoveryMessage = 'A saved configuration could not be restored. Defaults are available.';
      return null;
    }
  }

  Future<void> visit(String id) async {
    lastLab = id;
    await preferences.setString('lastLab', id);
    await preferences.setString('lastStudio', id.split('-').first);
    notifyListeners();
  }

  Future<void> recordAttempt(String labId, Map<String, dynamic> attempt) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    if (_db != null) {
      await _db!.insert('challenge_attempts', {
        'id': id,
        'lab_id': labId,
        'body': jsonEncode(attempt),
      });
    } else {
      await preferences.setStringList('attempts:$labId', [
        ...preferences.getStringList('attempts:$labId') ?? [],
        jsonEncode(attempt),
      ]);
    }
  }

  Future<void> complete(String id) async {
    completed.add(id);
    await preferences.setStringList('completed', completed.toList());
    notifyListeners();
  }

  Future<void> settings({bool? motion, bool? touch}) async {
    reducedMotion = motion ?? reducedMotion;
    haptics = touch ?? haptics;
    await preferences.setBool('reducedMotion', reducedMotion);
    await preferences.setBool('haptics', haptics);
    notifyListeners();
  }
}

String csvEncode(List<Trial> trials) {
  String cell(Object? x) => '"${(x?.toString() ?? '').replaceAll('"', '""')}"';
  return [
    'id,lab_id,created_utc,quantity,value_SI,unit_SI,resolution_SI,notes,model,configuration_json',
    ...trials.map(
      (t) => [
        t.id,
        t.labId,
        t.created,
        t.quantity,
        t.value,
        t.unit,
        t.resolution,
        t.note,
        t.model,
        jsonEncode(t.configuration),
      ].map(cell).join(','),
    ),
  ].join('\r\n');
}
