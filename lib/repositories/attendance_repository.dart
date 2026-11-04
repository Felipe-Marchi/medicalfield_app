import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/attendance.dart';

// Classe auxiliar de transferencia de dados combinando o Atendimento, Paciente e Prontuario para a UI.
class AttendanceItem {
  final Attendance attendance;
  final String patientName;
  final String? medicalRecordObservations;

  AttendanceItem({
    required this.attendance,
    required this.patientName,
    this.medicalRecordObservations,
  });
}

// Repositorio responsavel pelas operacoes no banco de dados SQLite local para a tabela de atendimentos.
class AttendanceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Retorna a lista completa de atendimentos com dados do paciente e prontuario do SQLite local.
  Future<List<AttendanceItem>> getAllAttendancesWithDetails() async {
    final db = await _dbHelper.database;

    const String query = '''
      SELECT 
        a.patient_cpf,
        a.attendance_datetime,
        a.professional_id,
        a.glasgow_scale,
        a.triage_classification,
        a.blood_pressure,
        a.heart_rate,
        a.oxygen_saturation,
        a.administered_medications,
        a.synchronized,
        p.name AS patient_name,
        m.observations AS medical_record_observations
      FROM attendances a
      LEFT JOIN patients p ON a.patient_cpf = p.cpf
      LEFT JOIN medical_records m ON a.patient_cpf = m.patient_cpf
      ORDER BY a.attendance_datetime DESC
    ''';

    final List<Map<String, dynamic>> result = await db.rawQuery(query);

    return result.map((map) {
      final attendance = Attendance.fromMap(map);
      final String patientName = (map['patient_name'] as String?) ?? 'Paciente Desconhecido';
      final String? observations = map['medical_record_observations'] as String?;

      return AttendanceItem(
        attendance: attendance,
        patientName: patientName,
        medicalRecordObservations: observations,
      );
    }).toList();
  }

  // Retorna todos os atendimentos pendentes de sincronizacao (synchronized = 0).
  Future<List<Attendance>> getUnsynchronizedAttendances() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendances',
      where: 'synchronized = ?',
      whereArgs: [0],
    );

    return maps.map((map) => Attendance.fromMap(map)).toList();
  }

  // Salva um novo atendimento no SQLite local.
  Future<void> saveAttendance(Attendance attendance) async {
    final db = await _dbHelper.database;
    await db.insert(
      'attendances',
      attendance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Salva uma lista de atendimentos baixados da API no SQLite local.
  Future<void> saveAttendances(List<Attendance> attendances) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var attendance in attendances) {
      batch.insert(
        'attendances',
        attendance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Marca um atendimento como sincronizado (synchronized = 1).
  Future<void> markAsSynchronized(String patientCpf, String attendanceDatetime) async {
    final db = await _dbHelper.database;
    await db.update(
      'attendances',
      {'synchronized': 1},
      where: 'patient_cpf = ? AND attendance_datetime = ?',
      whereArgs: [patientCpf, attendanceDatetime],
    );
  }
}
