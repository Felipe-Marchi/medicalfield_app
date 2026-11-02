import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Classe responsável pelo gerenciamento do banco de dados SQLite local no dispositivo.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // Retorna a instância ativa do banco de dados SQLite ou inicializa uma nova.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa o arquivo do banco de dados local.
  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, 'medicalfield_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Executa o script DDL de criação das tabelas locais quando o banco é criado.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabela de Profissionais
    // (Armazena dados do socorrista autenticado online para vinculação nos atendimentos offline. Não possui senha por segurança).
    await db.execute('''
      CREATE TABLE professionals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Tabela de Pacientes
    await db.execute('''
      CREATE TABLE patients (
        cpf TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        birth_date TEXT,
        gender TEXT
      )
    ''');

    // 3. Tabela de Prontuários Médicos
    await db.execute('''
      CREATE TABLE medical_records (
        patient_cpf TEXT PRIMARY KEY,
        opening_date TEXT NOT NULL,
        observations TEXT,
        FOREIGN KEY (patient_cpf) REFERENCES patients (cpf) ON DELETE RESTRICT
      )
    ''');

    // 4. Tabela de Medicamentos
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        concentration TEXT
      )
    ''');

    // 5. Tabela de Atendimentos de Emergência
    await db.execute('''
      CREATE TABLE attendances (
        patient_cpf TEXT NOT NULL,
        attendance_datetime TEXT NOT NULL,
        professional_id INTEGER NOT NULL,
        glasgow_scale INTEGER NOT NULL,
        triage_classification TEXT NOT NULL,
        blood_pressure TEXT,
        heart_rate INTEGER,
        oxygen_saturation INTEGER,
        administered_medications TEXT,
        synchronized INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (patient_cpf, attendance_datetime)
      )
    ''');
  }
}
