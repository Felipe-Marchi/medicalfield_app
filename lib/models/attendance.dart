// Modelo que representa o atendimento clinico de emergencia realizado pelo socorrista.
class Attendance {
  final String patientCpf;
  final String attendanceDatetime;
  final int professionalId;
  final int glasgowScale;
  final String triageClassification;
  final String? bloodPressure;
  final int? heartRate;
  final int? oxygenSaturation;
  final String? administeredMedications;
  final bool synchronized;

  Attendance({
    required this.patientCpf,
    required this.attendanceDatetime,
    required this.professionalId,
    required this.glasgowScale,
    required this.triageClassification,
    this.bloodPressure,
    this.heartRate,
    this.oxygenSaturation,
    this.administeredMedications,
    this.synchronized = false,
  });

  // Converte o objeto para um Mapa para ser salvo no banco de dados SQLite local.
  Map<String, dynamic> toMap() {
    return {
      'patient_cpf': patientCpf,
      'attendance_datetime': attendanceDatetime,
      'professional_id': professionalId,
      'glasgow_scale': glasgowScale,
      'triage_classification': triageClassification,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'oxygen_saturation': oxygenSaturation,
      'administered_medications': administeredMedications,
      // No SQLite, o status de sincronizacao e mantido como 0 (pendente) ou 1 (sincronizado)
      'synchronized': synchronized ? 1 : 0,
    };
  }

  // Cria uma instancia de Attendance a partir do banco de dados SQLite local.
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      patientCpf: map['patient_cpf'] as String,
      attendanceDatetime: map['attendance_datetime'] as String,
      professionalId: map['professional_id'] as int,
      glasgowScale: map['glasgow_scale'] as int,
      triageClassification: map['triage_classification'] as String,
      bloodPressure: map['blood_pressure'] as String?,
      heartRate: map['heart_rate'] as int?,
      oxygenSaturation: map['oxygen_saturation'] as int?,
      administeredMedications: map['administered_medications'] as String?,
      synchronized: map['synchronized'] == 1,
    );
  }

  // Converte o objeto para JSON para o DTO de sincronizacao com a API REST Spring Boot (AttendanceDTO).
  Map<String, dynamic> toJson() {
    return {
      'professionalId': professionalId,
      'glasgowScale': glasgowScale,
      'triageClassification': triageClassification,
      'bloodPressure': bloodPressure,
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
      'administeredMedications': administeredMedications,
    };
  }

  // Cria uma instancia de Attendance a partir do JSON da API REST.
  factory Attendance.fromJson(Map<String, dynamic> json, {required String patientCpf, required String attendanceDatetime}) {
    return Attendance(
      patientCpf: patientCpf,
      attendanceDatetime: attendanceDatetime,
      professionalId: json['professionalId'] as int,
      glasgowScale: json['glasgowScale'] as int,
      triageClassification: json['triageClassification'] as String,
      bloodPressure: json['bloodPressure'] as String?,
      heartRate: json['heartRate'] as int?,
      oxygenSaturation: json['oxygenSaturation'] as int?,
      administeredMedications: json['administeredMedications'] as String?,
      synchronized: true,
    );
  }

  // Cria uma copia atualizada alterando o status de sincronizacao.
  Attendance copyWith({bool? synchronized}) {
    return Attendance(
      patientCpf: patientCpf,
      attendanceDatetime: attendanceDatetime,
      professionalId: professionalId,
      glasgowScale: glasgowScale,
      triageClassification: triageClassification,
      bloodPressure: bloodPressure,
      heartRate: heartRate,
      oxygenSaturation: oxygenSaturation,
      administeredMedications: administeredMedications,
      synchronized: synchronized ?? this.synchronized,
    );
  }
}
