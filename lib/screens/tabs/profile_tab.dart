import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../services/session_service.dart';
import '../../services/sync_service.dart';
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

  // Limpa todos os dados locais do banco SQLite (atendimentos, pacientes, prontuarios e medicamentos).
  Future<void> _handleClearLocalDatabase() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Banco Local?'),
        content: const Text(
          'Esta ação apagará todos os dados salvos neste celular (Atendimentos, Pacientes, Prontuários e Medicamentos). Você poderá sincronizar tudo novamente em seguida.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar Dados'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().clearAllData();
      SyncService().notifyDataChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banco local limpo com sucesso! Toque em Sincronizar (🔄) no topo para recarregar.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
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
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep, color: Colors.orange),
              label: const Text('Resetar Banco Local (Testes)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade900,
                side: BorderSide(color: Colors.orange.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _handleClearLocalDatabase,
            ),
            const SizedBox(height: 16),
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
