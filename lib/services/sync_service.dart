import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/medication.dart';
import '../models/patient.dart';
import '../repositories/medication_repository.dart';
import '../repositories/patient_repository.dart';
import 'api_config.dart';
import 'network_service.dart';

// Servico reativo responsavel pelas rotinas de sincronizacao de dados entre a API e o SQLite local.
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final MedicationRepository _medicationRepository = MedicationRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final NetworkService _networkService = NetworkService();

  // Executa a sincronizacao completa de dados (Medicamentos e Pacientes).
  Future<void> syncAllData() async {
    if (!_networkService.isOnline) {
      throw Exception('O aplicativo está em modo OFFLINE. Alterne para ONLINE no topo para sincronizar.');
    }

    await syncMedications(notify: false);
    await syncPatients(notify: false);

    // Notifica todas as abas ativas para recarregarem os dados do SQLite instantaneamente
    notifyListeners();
  }

  // Baixa a lista de medicamentos da API REST, limpa e atualiza o banco local.
  Future<void> syncMedications({bool notify = true}) async {
    if (!_networkService.isOnline) {
      throw Exception('O aplicativo está em modo OFFLINE. Alterne para ONLINE no topo para sincronizar.');
    }

    final String url = '${ApiConfig.baseUrl}/medications';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;

        final List<Medication> medications = jsonList
            .map((item) => Medication.fromJson(item as Map<String, dynamic>))
            .toList();

        // Limpa a tabela local e salva a lista atualizada trazida da API
        await _medicationRepository.clearAndSaveMedications(medications);

        if (notify) notifyListeners();
      } else {
        throw Exception('Falha ao buscar medicamentos na API (Status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao sincronizar medicamentos: $e');
    }
  }

  // Baixa a lista de pacientes da API REST e atualiza/insere no banco local.
  Future<void> syncPatients({bool notify = true}) async {
    if (!_networkService.isOnline) {
      throw Exception('O aplicativo está em modo OFFLINE. Alterne para ONLINE no topo para sincronizar.');
    }

    final String url = '${ApiConfig.baseUrl}/patients';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;

        final List<Patient> patients = jsonList
            .map((item) => Patient.fromJson(item as Map<String, dynamic>))
            .toList();

        // Salva/atualiza a lista de pacientes no banco SQLite local (preservando cadastros)
        await _patientRepository.savePatients(patients);

        if (notify) notifyListeners();
      } else {
        throw Exception('Falha ao buscar pacientes na API (Status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao sincronizar pacientes: $e');
    }
  }
}
