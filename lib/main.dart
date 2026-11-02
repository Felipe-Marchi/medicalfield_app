import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verifica se o socorrista ja possui uma sessao ativa iniciada
  final SessionService sessionService = SessionService();
  final bool isLoggedIn = await sessionService.isLoggedIn();

  runApp(MedicalFieldApp(isLoggedIn: isLoggedIn));
}

// Aplicativo principal do projeto MedicalField.
class MedicalFieldApp extends StatelessWidget {
  final bool isLoggedIn;

  const MedicalFieldApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedicalField',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      // Se ja estiver logado, vai direto para a HomeScreen; caso contrario, abre a LoginScreen
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
