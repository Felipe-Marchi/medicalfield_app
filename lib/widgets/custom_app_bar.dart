import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/sync_service.dart';

// Barra superior (AppBar) padronizada do aplicativo MedicalField.
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;

  // Executa a rotina de sincronizacao de dados completa
  Future<void> _handleSync(BuildContext context) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _syncService.syncAllData();
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sincronização realizada'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkService = NetworkService();

    return AppBar(
      title: Text(
        widget.title,
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

        // Botao de Sincronizar Dados
        _isSyncing
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sincronizar Dados',
                onPressed: widget.onSyncPressed ?? () => _handleSync(context),
              ),
        const SizedBox(width: 8),
      ],
    );
  }
}
