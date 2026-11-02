import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/professional.dart';
import 'api_config.dart';

// Servico responsavel por realizar a autenticacao online do socorrista com a API REST Spring Boot.
class AuthService {
  // Autentica o socorrista enviando usuario e senha para a API REST Spring Boot.
  // Retorna o objeto Professional se o login for bem-sucedido.
  Future<Professional?> login(String username, String password) async {
    final String url = '${ApiConfig.baseUrl}/professionals/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
        return Professional.fromJson(jsonMap);
      } else if (response.statusCode == 401) {
        // Usuario ou senha invalidos
        return null;
      } else {
        throw Exception('Falha na autenticação (Status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro de conexão com a API: $e');
    }
  }
}
