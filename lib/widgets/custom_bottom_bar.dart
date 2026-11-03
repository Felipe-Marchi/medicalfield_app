import 'package:flutter/material.dart';

// Barra de navegacao inferior (BottomNavigationBar) padronizada do aplicativo.
class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          activeIcon: Icon(Icons.assignment, color: Colors.redAccent),
          label: 'Atendimentos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          activeIcon: Icon(Icons.people, color: Colors.redAccent),
          label: 'Pacientes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication),
          activeIcon: Icon(Icons.medication, color: Colors.redAccent),
          label: 'Medicamentos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          activeIcon: Icon(Icons.person, color: Colors.redAccent),
          label: 'Perfil',
        ),
      ],
    );
  }
}
