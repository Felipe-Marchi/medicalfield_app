import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/professional.dart';

// Repositorio responsavel pelas operacoes no banco de dados SQLite local para a tabela de profissionais.
class ProfessionalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Salva ou atualiza os dados do profissional autenticado no SQLite local.
  Future<void> saveProfessional(Professional professional) async {
    final db = await _dbHelper.database;
    await db.insert(
      'professionals',
      professional.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Busca um profissional pelo seu ID no banco local.
  Future<Professional?> getProfessionalById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'professionals',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Professional.fromMap(maps.first);
    }
    return null;
  }
}
