import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/medical_record.dart';

// Repositorio responsavel pelas operacoes no banco de dados SQLite local para a tabela de prontuarios medicos.
class MedicalRecordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Salva ou atualiza um prontuario no banco SQLite local.
  Future<void> saveMedicalRecord(MedicalRecord record) async {
    final db = await _dbHelper.database;
    await db.insert(
      'medical_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Salva ou atualiza uma lista de prontuarios baixada da API.
  Future<void> saveMedicalRecords(List<MedicalRecord> records) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var record in records) {
      batch.insert(
        'medical_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Busca o prontuario de um paciente pelo CPF.
  Future<MedicalRecord?> getMedicalRecordByCpf(String cpf) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medical_records',
      where: 'patient_cpf = ?',
      whereArgs: [cpf],
    );

    if (maps.isNotEmpty) {
      return MedicalRecord.fromMap(maps.first);
    }
    return null;
  }
}
