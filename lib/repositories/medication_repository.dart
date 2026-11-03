import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/medication.dart';

// Repositorio responsavel pelas operacoes no banco de dados SQLite local para a tabela de medicamentos.
class MedicationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Retorna a lista de todos os medicamentos salvos no SQLite local.
  Future<List<Medication>> getAllMedications() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      orderBy: 'name ASC',
    );

    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  // Salva ou atualiza uma lista de medicamentos baixados da API no banco local.
  Future<void> saveMedications(List<Medication> medications) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var medication in medications) {
      batch.insert(
        'medications',
        medication.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
}
