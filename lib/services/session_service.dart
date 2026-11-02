import 'package:shared_preferences/shared_preferences.dart';
import '../models/professional.dart';

// Servico responsavel pelo gerenciamento da sessao do socorrista logado no aplicativo.
class SessionService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyProfessionalId = 'professional_id';
  static const String _keyProfessionalName = 'professional_name';
  static const String _keyProfessionalUsername = 'professional_username';

  // Salva os dados da sessao do socorrista autenticado.
  Future<void> saveSession(Professional professional) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    if (professional.id != null) {
      await prefs.setInt(_keyProfessionalId, professional.id!);
    }
    await prefs.setString(_keyProfessionalName, professional.name);
    await prefs.setString(_keyProfessionalUsername, professional.username);
  }

  // Verifica se existe um socorrista com sessao ativa.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Retorna o ID do socorrista logado no momento.
  Future<int?> getActiveProfessionalId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyProfessionalId);
  }

  // Retorna o Nome do socorrista logado no momento.
  Future<String?> getActiveProfessionalName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfessionalName);
  }

  // Encerra a sessao ativa do socorrista (Logout).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyProfessionalId);
    await prefs.remove(_keyProfessionalName);
    await prefs.remove(_keyProfessionalUsername);
  }
}
