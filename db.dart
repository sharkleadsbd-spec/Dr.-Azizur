import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Appt {
  final int id, patientId, age, serial;
  final String name, phone, date, type, status, notes;
  const Appt({required this.id, required this.patientId, required this.name, required this.age, required this.phone,
      required this.date, required this.serial, required this.type, required this.status, required this.notes});
  factory Appt.fromMap(Map<String, Object?> m) => Appt(
        id: m['id'] as int,
        patientId: m['patient_id'] as int,
        name: m['name'] as String,
        age: m['age'] as int,
        phone: m['phone'] as String,
        date: m['appt_date'] as String,
        serial: m['serial'] as int,
        type: m['patient_type'] as String,
        status: m['status'] as String,
        notes: (m['notes'] ?? '') as String,
      );
  String get serialLabel => serial.toString().padLeft(3, '0');
}

class Db {
  Db._();
  static final Db I = Db._();
  static const _file = 'doctor_app.db';
  Database? _db;

  Future<String> get path async => p.join(await getDatabasesPath(), _file);
  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async => openDatabase(
        await path,
        version: 1,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: (d, v) async {
          await d.execute('''CREATE TABLE patients(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, age INTEGER NOT NULL,
            phone TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL)''');
          await d.execute('''CREATE TABLE appointments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
            appt_date TEXT NOT NULL, serial INTEGER NOT NULL,
            patient_type TEXT NOT NULL CHECK(patient_type IN ('New','Old')),
            status TEXT NOT NULL DEFAULT 'Confirmed',
            notes TEXT, created_at TEXT NOT NULL,
            UNIQUE(appt_date, serial))''');
          await d.execute('CREATE INDEX idx_appt_date ON appointments(appt_date)');
        },
      );

  static const _sel = '''SELECT a.id, a.patient_id, p.name, p.age, p.phone, a.appt_date, a.serial,
      a.patient_type, a.status, COALESCE(a.notes,'') AS notes
      FROM appointments a JOIN patients p ON p.id = a.patient_id''';

  Future<int> nextSerial(String date) async => Sqflite.firstIntValue(await (await db).rawQuery(
          'SELECT COALESCE(MAX(serial),0)+1 FROM appointments WHERE appt_date=?', [date])) ??
      1;

  Future<Appt?> getById(int id) async {
    final r = await (await db).rawQuery('$_sel WHERE a.id=?', [id]);
    return r.isEmpty ? null : Appt.fromMap(r.first);
  }

  /// Serial is computed inside one transaction; UNIQUE(appt_date, serial) guarantees no duplicates.
  /// Cancelled appointments keep their serial (never reused) so ordering stays stable.
  Future<Appt> createAppointment({required String name, required int age, required String phone,
      required String type, required String date, String notes = ''}) async {
    final d = await db;
    late int apptId;
    await d.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final ex = await txn.query('patients', where: 'phone=?', whereArgs: [phone], limit: 1);
      int pid;
      if (ex.isEmpty) {
        pid = await txn.insert('patients', {'name': name, 'age': age, 'phone': phone, 'created_at': now});
      } else {
        pid = ex.first['id'] as int;
        await txn.update('patients', {'name': name, 'age': age}, where: 'id=?', whereArgs: [pid]);
        final dup = await txn.rawQuery(
            "SELECT 1 FROM appointments WHERE patient_id=? AND appt_date=? AND status<>'Cancelled'", [pid, date]);
        if (dup.isNotEmpty) throw Exception('duplicate');
      }
      final n = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COALESCE(MAX(serial),0)+1 FROM appointments WHERE appt_date=?', [date]))!;
      apptId = await txn.insert('appointments', {
        'patient_id': pid, 'appt_date': date, 'serial': n, 'patient_type': type,
        'status': 'Confirmed', 'notes': notes, 'created_at': now,
      });
    });
    return (await getById(apptId))!;
  }

  Future<void> updateAppointment(Appt a, {required String name, required int age, required String phone,
      required String type, String notes = ''}) async {
    final d = await db;
    await d.transaction((txn) async {
      final clash = await txn.query('patients', where: 'phone=? AND id<>?', whereArgs: [phone, a.patientId]);
      if (clash.isNotEmpty) throw Exception('phoneUsed');
      await txn.update('patients', {'name': name, 'age': age, 'phone': phone}, where: 'id=?', whereArgs: [a.patientId]);
      await txn.update('appointments', {'patient_type': type, 'notes': notes}, where: 'id=?', whereArgs: [a.id]);
    });
  }

  Future<void> setStatus(int id, String status) async =>
      (await db).update('appointments', {'status': status}, where: 'id=?', whereArgs: [id]);

  Future<List<Appt>> query({String? date, String? from, String? to, String? search, String? type, String? status}) async {
    final w = <String>[];
    final args = <Object?>[];
    if (date != null) { w.add('a.appt_date=?'); args.add(date); }
    if (from != null) { w.add('a.appt_date>=?'); args.add(from); }
    if (to != null) { w.add('a.appt_date<=?'); args.add(to); }
    if (type != null) { w.add('a.patient_type=?'); args.add(type); }
    if (status != null) { w.add('a.status=?'); args.add(status); }
    if (search != null && search.isNotEmpty) {
      w.add('(p.name LIKE ? OR p.phone LIKE ?)');
      args..add('%$search%')..add('%$search%');
    }
    final sql = '$_sel ${w.isEmpty ? '' : 'WHERE ${w.join(' AND ')}'} ORDER BY a.appt_date DESC, a.serial ASC';
    return (await (await db).rawQuery(sql, args)).map(Appt.fromMap).toList();
  }

  Future<List<Appt>> history(int patientId) async =>
      (await (await db).rawQuery('$_sel WHERE a.patient_id=? ORDER BY a.appt_date DESC, a.serial', [patientId]))
          .map(Appt.fromMap).toList();

  Future<Map<String, int>> stats(String date) async {
    final d = await db;
    Future<int> c(String where, [List<Object?> a = const []]) async =>
        Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM appointments WHERE $where', a)) ?? 0;
    const live = "status<>'Cancelled'";
    return {
      'tTotal': await c('appt_date=? AND $live', [date]),
      'tNew': await c("appt_date=? AND $live AND patient_type='New'", [date]),
      'tOld': await c("appt_date=? AND $live AND patient_type='Old'", [date]),
      'aTotal': await c(live),
      'aNew': await c("$live AND patient_type='New'"),
      'aOld': await c("$live AND patient_type='Old'"),
    };
  }

  /// Copies the database file to app storage and returns its path (caller shares it).
  Future<String> backup() async {
    await _db?.close();
    _db = null;
    try {
      final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'backups'));
      await dir.create(recursive: true);
      final out = p.join(dir.path, 'doctor_app_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db');
      await File(await path).copy(out);
      return out;
    } finally {
      await db; // reopen
    }
  }

  Future<void> restore(File f) async {
    final head = await f.openRead(0, 16).first;
    if (String.fromCharCodes(head) != 'SQLite format 3\u0000') {
      throw Exception('Not a valid database backup file');
    }
    await _db?.close();
    _db = null;
    final dest = await path;
    for (final s in ['-wal', '-shm', '-journal']) {
      final x = File(dest + s);
      if (await x.exists()) await x.delete();
    }
    await f.copy(dest);
    await db;
  }
}
