import 'package:flutter/material.dart';
import '../../repositories/attendance_repository.dart';

// Conteudo da Aba de Atendimentos exibindo os registros salvos no SQLite local.
class AttendancesTab extends StatefulWidget {
  const AttendancesTab({super.key});

  @override
  State<AttendancesTab> createState() => _AttendancesTabState();
}

class _AttendancesTabState extends State<AttendancesTab> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  List<AttendanceItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  // Carrega os atendimentos do SQLite local.
  Future<void> _loadAttendances() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<AttendanceItem> list =
          await _attendanceRepository.getAllAttendancesWithDetails();
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Formata o CPF para o padrao 000.000.000-00.
  String _formatCpf(String cpf) {
    final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cleanCpf.length == 11) {
      return '${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3, 6)}.${cleanCpf.substring(6, 9)}-${cleanCpf.substring(9, 11)}';
    }
    return cpf;
  }

  // Formata a data ISO8601 para o padrao dd/MM/yyyy HH:mm.
  String _formatDateTime(String dateTimeStr) {
    try {
      final parts = dateTimeStr.split('T');
      final dateParts = parts[0].split('-');
      final timeParts = parts.length > 1 ? parts[1].split(':') : ['00', '00'];

      if (dateParts.length == 3) {
        final dateFormatted = '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
        final timeFormatted = '${timeParts[0]}:${timeParts[1]}';
        return '$dateFormatted às $timeFormatted';
      }
    } catch (_) {}
    return dateTimeStr;
  }

  // Retorna a cor correspondente a classificacao da triagem.
  Color _getTriageColor(String classification) {
    final lower = classification.toLowerCase();
    if (lower.contains('vermelho')) return Colors.red;
    if (lower.contains('laranja')) return Colors.orange;
    if (lower.contains('amarelo')) return Colors.amber.shade700;
    if (lower.contains('verde')) return Colors.green;
    if (lower.contains('azul')) return Colors.blue;
    return Colors.grey;
  }

  // Exibe o Modal/BottomSheet com as observacoes do Prontuario Medico.
  void _showRecordModal(BuildContext context, AttendanceItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Observações do Prontuário',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Text(
                'Paciente: ${item.patientName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.medicalRecordObservations != null &&
                          item.medicalRecordObservations!.isNotEmpty
                      ? item.medicalRecordObservations!
                      : 'Nenhuma observação registrada para este paciente.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Exibe o Modal/BottomSheet com os Medicamentos Administrados.
  void _showMedicationsModal(BuildContext context, AttendanceItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Medicamentos Administrados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.attendance.administeredMedications != null &&
                          item.attendance.administeredMedications!.isNotEmpty
                      ? item.attendance.administeredMedications!
                      : 'Nenhum medicamento registrado neste atendimento.',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAttendances,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(32.0),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum atendimento no dispositivo',
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
      onRefresh: _loadAttendances,
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final att = item.attendance;
          final triageColor = _getTriageColor(att.triageClassification);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecalho: Data/Hora + Triagem Badge + Status Sync
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDateTime(att.attendanceDatetime),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          // Badge de Triagem
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: triageColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              att.triageClassification.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Badge de Status da Sincronizacao (Enviado / Pendente)
                          Icon(
                            att.synchronized
                                ? Icons.cloud_done
                                : Icons.cloud_upload,
                            size: 20,
                            color: att.synchronized
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Nome do Paciente e CPF
                  Text(
                    item.patientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Text(
                    'CPF: ${_formatCpf(att.patientCpf)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Divider(height: 20),

                  // Grid/Linha de Sinais Vitais
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildVitalSign('PA', att.bloodPressure ?? '--'),
                      _buildVitalSign('Glasgow', '${att.glasgowScale}'),
                      _buildVitalSign('Freq.', att.heartRate != null ? '${att.heartRate} bpm' : '--'),
                      _buildVitalSign('Sat O2', att.oxygenSaturation != null ? '${att.oxygenSaturation}%' : '--'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Botoes de Acao: Medicamentos e Prontuario
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.medical_services, size: 16),
                          label: const Text('Medicamentos', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showMedicationsModal(context, item),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.description, size: 16),
                          label: const Text('Prontuário', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showRecordModal(context, item),
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

  // Widget auxiliar para exibir cada Sinal Vital
  Widget _buildVitalSign(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
