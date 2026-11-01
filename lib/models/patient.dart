// Modelo que representa o paciente atendido no sistema.
class Patient {
  final String cpf;
  final String name;
  final String? birthDate;
  final String? gender;

  Patient({
    required this.cpf,
    required this.name,
    this.birthDate,
    this.gender,
  });

  // Converte o objeto para um Mapa para o SQLite local.
  Map<String, dynamic> toMap() {
    return {
      'cpf': cpf,
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
    };
  }

  // Cria uma instância de Patient a partir do SQLite local.
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      cpf: map['cpf'] as String,
      name: map['name'] as String,
      birthDate: map['birth_date'] as String?,
      gender: map['gender'] as String?,
    );
  }

  // Converte o objeto para JSON para envio à API REST (Spring Boot).
  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'name': name,
      'birthDate': birthDate,
      'gender': gender,
    };
  }

  // Cria uma instância de Patient a partir do JSON retornado pela API.
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      cpf: json['cpf'] as String,
      name: json['name'] as String,
      birthDate: json['birthDate'] as String?,
      gender: json['gender'] as String?,
    );
  }
}
