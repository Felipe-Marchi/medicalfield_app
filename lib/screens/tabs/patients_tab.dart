import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../repositories/patient_repository.dart';
import '../../services/sync_service.dart';

// Conteudo da Aba de Pacientes exibindo a lista armazenada no SQLite local.
class PatientsTab extends StatefulWidget {
  const PatientsTab({super.key});

  @override
  State<PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<PatientsTab> {
  final PatientRepository _patientRepository = PatientRepository();
  final SyncService _syncService = SyncService();
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    // Ouve os eventos de sincronizacao concluida para atualizar a lista automaticamente
    _syncService.addListener(_loadPatients);
  }

  @override
  void dispose() {
    _syncService.removeListener(_loadPatients);
    super.dispose();
  }

  // Carrega a lista de pacientes armazenados no banco local.
  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Patient> list = await _patientRepository.getAllPatients();
      if (!mounted) return;
      setState(() {
        _patients = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Formata a String do CPF (11 digitos) para o padrao 000.000.000-00.
  String _formatCpf(String cpf) {
    final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cleanCpf.length == 11) {
      return '${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3, 6)}.${cleanCpf.substring(6, 9)}-${cleanCpf.substring(9, 11)}';
    }
    return cpf;
  }

  // Formata a data ISO8601 (YYYY-MM-DD) para o padrao brasileiro dd/MM/yyyy.
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Não informada';
    try {
      final parts = dateStr.split('T')[0].split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    if (_patients.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPatients,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(32.0),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum paciente no dispositivo',
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
      onRefresh: _loadPatients,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final patient = _patients[index];

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coluna Esquerda: Nome do Paciente e CPF destacado logo abaixo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CPF: ${_formatCpf(patient.cpf)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Coluna Direita: Data de Nascimento e Genero
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(patient.birthDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gênero: ${patient.gender ?? '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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
