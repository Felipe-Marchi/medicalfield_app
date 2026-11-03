import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_bar.dart';
import 'tabs/attendances_tab.dart';
import 'tabs/medications_tab.dart';
import 'tabs/patients_tab.dart';
import 'tabs/profile_tab.dart';

// Tela principal do aplicativo mantendo as barras superior e inferior fixas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista das abas navegaveis no centro da tela
  final List<Widget> _tabs = const [
    // Aba 1: Painel de Atendimentos
    AttendancesTab(),
    // Aba 2: Lista de Pacientes
    PatientsTab(),
    // Aba 3: Catálogo de Medicamentos
    MedicationsTab(),
    // Aba 4: Perfil do Socorrista
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
