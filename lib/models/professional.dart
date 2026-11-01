// Modelo que representa o profissional de saúde/socorrista no sistema.
class Professional {
  final int? id;
  final String username;
  final String name;
  final bool active;

  Professional({
    this.id,
    required this.username,
    required this.name,
    this.active = true,
  });

  // Converte o objeto para um Mapa utilizado na inserção no banco de dados SQLite local.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'name': name,
      // No SQLite, valores booleanos são armazenados como inteiros (1 para verdadeiro, 0 para falso)
      'active': active ? 1 : 0,
    };
  }

  // Cria uma instância de Professional a partir de um registro lido do SQLite local.
  factory Professional.fromMap(Map<String, dynamic> map) {
    return Professional(
      id: map['id'] as int?,
      username: map['username'] as String,
      name: map['name'] as String,
      active: map['active'] == 1,
    );
  }

  // Converte o objeto para JSON para envio nas requisições HTTP REST.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'active': active,
    };
  }

  // Cria uma instância a partir do JSON retornado pela API Spring Boot.
  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      id: json['id'] as int?,
      username: json['username'] as String,
      name: json['name'] as String,
      active: json['active'] as bool? ?? true,
    );
  }
}
