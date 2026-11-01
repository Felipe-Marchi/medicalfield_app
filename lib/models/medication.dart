// Modelo que representa um medicamento do catálogo.
class Medication {
  final int? id;
  final String name;
  final String? concentration;

  Medication({
    this.id,
    required this.name,
    this.concentration,
  });

  // Converte o objeto para um Mapa para armazenamento no SQLite local.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'concentration': concentration,
    };
  }

  // Cria uma instância de Medication a partir do SQLite local.
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      concentration: map['concentration'] as String?,
    );
  }

  // Converte o objeto para JSON para requisições HTTP.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'concentration': concentration,
    };
  }

  // Cria uma instância de Medication a partir do JSON retornado pela API.
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int?,
      name: json['name'] as String,
      concentration: json['concentration'] as String?,
    );
  }
}
