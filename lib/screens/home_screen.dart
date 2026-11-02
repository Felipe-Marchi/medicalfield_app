import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'login_screen.dart';

// Tela principal inicial do aplicativo pos-login.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SessionService _sessionService = SessionService();
  String _professionalName = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  // Carrega as informacoes do socorrista armazenadas na sessao ativa.
  Future<void> _loadSessionInfo() async {
    final String? name = await _sessionService.getActiveProfessionalName();
    setState(() {
      _professionalName = name ?? 'Socorrista';
    });
  }

  // Realiza o logout e encerra a sessao ativa.
  Future<void> _handleLogout() async {
    await _sessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedicalField - Início'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 70,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Sessão Ativa\n$_professionalName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sessão autenticada online com sucesso.\nO aplicativo está pronto para operar em modo offline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
