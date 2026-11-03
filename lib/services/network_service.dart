import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Servico responsavel pelo controle e estado do simulador de conectividade (Online/Offline) no aplicativo.
class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal() {
    _loadSimulatedStatus();
  }

  static const String _keyIsOnline = 'simulated_is_online';
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  // Carrega o estado salvo do simulador do SharedPreferences.
  Future<void> _loadSimulatedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnline = prefs.getBool(_keyIsOnline) ?? true;
    notifyListeners();
  }

  // Alterna o estado da conexao simulada entre Online e Offline.
  Future<void> toggleConnectivity() async {
    _isOnline = !_isOnline;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsOnline, _isOnline);
    notifyListeners();
  }
}
