import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../repositories/patient_repository.dart';

// Conteudo da Aba de Pacientes exibindo a lista armazenada no SQLite local.
class PatientsTab extends StatefulWidget {
  const PatientsTab({super.key});

  @override
  State<PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<PatientsTab> {
  final PatientRepository _patientRepository = PatientRepository();
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
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
        padding: const EdgeInsets.all(12.0),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final patient = _patients[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
              ),
              title: Text(
                patient.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'CPF: ${_formatCpf(patient.cpf)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nascimento: ${_formatDate(patient.birthDate)} | Gênero: ${patient.gender ?? '-'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
