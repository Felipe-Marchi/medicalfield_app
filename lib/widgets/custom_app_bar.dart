import 'package:flutter/material.dart';
import '../services/network_service.dart';

// Barra superior (AppBar) padronizada do aplicativo MedicalField.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSyncPressed;

  const CustomAppBar({
    super.key,
    this.title = 'MedicalField',
    this.onSyncPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final networkService = NetworkService();

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.redAccent,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Indicador e Seletor do Simulador de Conectividade (Online/Offline)
        ListenableBuilder(
          listenable: networkService,
          builder: (context, child) {
            final bool isOnline = networkService.isOnline;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await networkService.toggleConnectivity();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      networkService.isOnline
                          ? 'Modo de Conectividade: ONLINE'
                          : 'Modo de Conectividade: OFFLINE (Simulado)',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor:
                        networkService.isOnline ? Colors.green : Colors.orange,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),

        // Botao de Sincronizar Dados (Atualmente visual)
        IconButton(
          icon: const Icon(Icons.sync, color: Colors.white),
          tooltip: 'Sincronizar Dados',
          onPressed: onSyncPressed ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sincronização de dados acionada.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
