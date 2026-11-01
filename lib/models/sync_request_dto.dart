import 'attendance.dart';
import 'medical_record.dart';
import 'patient.dart';

// DTO responsavel por envelopar os dados de Paciente, Prontuario e Atendimento para a rota /attendances/sync do backend Spring Boot.
class SyncRequestDTO {
  final Patient patient;
  final MedicalRecord record;
  final Attendance attendance;

  SyncRequestDTO({
    required this.patient,
    required this.record,
    required this.attendance,
  });

  // Converte a estrutura DTO completa para o JSON aceito pelo Spring Boot (SyncRequestDTO.java).
  Map<String, dynamic> toJson() {
    return {
      'patient': patient.toJson(),
      'record': record.toJson(),
      'attendance': attendance.toJson(),
    };
  }
}
