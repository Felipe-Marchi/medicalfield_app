import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../login_screen.dart';

// Conteudo da Aba de Perfil do socorrista autenticado.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final SessionService _sessionService = SessionService();
  String _professionalName = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  // Carrega os dados do socorrista salvos na sessao ativa.
  Future<void> _loadSessionInfo() async {
    final String? name = await _sessionService.getActiveProfessionalName();
    if (!mounted) return;
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.redAccent,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _professionalName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Socorrista Autenticado',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sair da Sessão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}
