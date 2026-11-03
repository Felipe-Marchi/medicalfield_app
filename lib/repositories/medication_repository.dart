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

  // Limpa a tabela local e insere a lista atualizada de medicamentos baixada da API.
  Future<void> clearAndSaveMedications(List<Medication> medications) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Limpa o catalogo antigo para remover medicamentos deletados ou desatualizados
      await txn.delete('medications');

      // 2. Insere a lista atualizada trazida da API
      final batch = txn.batch();
      for (var medication in medications) {
        batch.insert(
          'medications',
          medication.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // Salva ou atualiza uma lista de medicamentos baixados da API no banco local.
  Future<void> saveMedications(List<Medication> medications) async {
    await clearAndSaveMedications(medications);
  }
}
