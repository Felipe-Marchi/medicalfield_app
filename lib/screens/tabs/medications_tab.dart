import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../repositories/medication_repository.dart';

// Conteudo da Aba de Medicamentos exibindo o catalogo salvo no SQLite local.
class MedicationsTab extends StatefulWidget {
  const MedicationsTab({super.key});

  @override
  State<MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends State<MedicationsTab> {
  final MedicationRepository _medicationRepository = MedicationRepository();
  List<Medication> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
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
        padding: const EdgeInsets.all(12.0),
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final medication = _medications[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.redAccent.shade100,
                child: Text(
                  medication.id != null ? '${medication.id}' : '-',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                medication.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                medication.concentration != null && medication.concentration!.isNotEmpty
                    ? 'Concentração: ${medication.concentration}'
                    : 'Sem concentração informada',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.medical_services,
                color: Colors.redAccent,
              ),
            ),
          );
        },
      ),
    );
  }
}
