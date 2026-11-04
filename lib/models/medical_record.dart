// Modelo que representa o prontuário médico do paciente.
class MedicalRecord {
  final String patientCpf;
  final String openingDate;
  final String? observations;

  MedicalRecord({
    required this.patientCpf,
    required this.openingDate,
    this.observations,
  });

  // Converte o objeto para um Mapa utilizado no SQLite local.
  Map<String, dynamic> toMap() {
    return {
      'patient_cpf': patientCpf,
      'opening_date': openingDate,
      'observations': observations,
    };
  }

  // Cria uma instância de MedicalRecord a partir do banco SQLite local.
  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      patientCpf: map['patient_cpf'] as String,
      openingDate: map['opening_date'] as String,
      observations: map['observations'] as String?,
    );
  }

  // Converte o objeto para JSON no formato exigido pela API (RecordDTO no Spring Boot).
  Map<String, dynamic> toJson() {
    return {
      'openingDate': openingDate,
      'observations': observations,
    };
  }

  // Cria uma instância de MedicalRecord a partir do JSON da API.
  factory MedicalRecord.fromJson(Map<String, dynamic> json, {String? patientCpf}) {
    return MedicalRecord(
      patientCpf: json['patientCpf'] as String? ?? patientCpf ?? '',
      openingDate: json['openingDate'] as String? ?? '',
      observations: json['observations'] as String?,
    );
  }
}
