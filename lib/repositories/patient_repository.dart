import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';

// Repositorio responsavel pelas operacoes no banco de dados SQLite local para a tabela de pacientes.
class PatientRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Retorna a lista de todos os pacientes salvos no SQLite local.
  Future<List<Patient>> getAllPatients() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patients',
      orderBy: 'name ASC',
    );

    return maps.map((map) => Patient.fromMap(map)).toList();
  }

  // Busca um paciente por CPF no banco de dados local.
  Future<Patient?> getPatientByCpf(String cpf) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patients',
      where: 'cpf = ?',
      whereArgs: [cpf],
    );

    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  // Salva ou atualiza um paciente no banco local.
  Future<void> savePatient(Patient patient) async {
    final db = await _dbHelper.database;
    await db.insert(
      'patients',
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Salva ou atualiza uma lista de pacientes no banco local.
  Future<void> savePatients(List<Patient> patients) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var patient in patients) {
      batch.insert(
        'patients',
        patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
}
