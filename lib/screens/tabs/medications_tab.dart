import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../repositories/medication_repository.dart';
import '../../services/sync_service.dart';

// Conteudo da Aba de Medicamentos exibindo o catalogo salvo no SQLite local.
class MedicationsTab extends StatefulWidget {
  const MedicationsTab({super.key});

  @override
  State<MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends State<MedicationsTab> {
  final MedicationRepository _medicationRepository = MedicationRepository();
  final SyncService _syncService = SyncService();
  List<Medication> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
    // Ouve os eventos de sincronizacao concluida para atualizar a lista automaticamente
    _syncService.addListener(_loadMedications);
  }

  @override
  void dispose() {
    _syncService.removeListener(_loadMedications);
    super.dispose();
  }

  // Carrega a lista de medicamentos armazenados no banco local.
  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Medication> list = await _medicationRepository.getAllMedications();
      if (!mounted) return;
      setState(() {
        _medications = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    if (_medications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMedications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(32.0),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum medicamento no dispositivo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final medication = _medications[index];
          final hasConcentration = medication.concentration != null && medication.concentration!.trim().isNotEmpty;

          return Card(
            color: Colors.white,
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.grey.shade300, width: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha Superior: Nome do Medicamento em negrito e ID simples na direita
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (medication.id != null)
                        Text(
                          '#${medication.id}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Linha Inferior: Concentracao em texto simples sem fundo
                  Text(
                    hasConcentration
                        ? 'Concentração: ${medication.concentration}'
                        : 'Sem concentração informada',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
