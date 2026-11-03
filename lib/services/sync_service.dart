import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/medication.dart';
import '../repositories/medication_repository.dart';
import 'api_config.dart';
import 'network_service.dart';

// Servico reativo responsavel pelas rotinas de sincronizacao de dados entre a API e o SQLite local.
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final MedicationRepository _medicationRepository = MedicationRepository();
  final NetworkService _networkService = NetworkService();

  // Baixa a lista de medicamentos da API REST, limpa e atualiza o banco de dados SQLite local.
  Future<void> syncMedications() async {
    // 1. Verifica se a conexao (real ou simulada) esta ativa
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

        // Notifica as abas ativas para recarregarem os dados do SQLite instantaneamente
        notifyListeners();
      } else {
        throw Exception('Falha ao buscar medicamentos na API (Status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao sincronizar medicamentos: $e');
    }
  }
}
