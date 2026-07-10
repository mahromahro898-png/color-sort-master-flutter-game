import 'package:flutter/material.dart';
import 'dart:async';
import 'game_screen.dart'; // Importação da tela de jogo (GameScreen) - Assegurar resolução correta do diretório
import 'home_screen.dart'; // Importação do Menu Principal (HomeScreen) - Ponto de entrada (Entrypoint) após o carregamento inicial
import '../services/sound_service.dart';

/// ══════════════════════════════════════════════════════════
///  splash_screen.dart
///  Tela de Abertura (Splash Screen) - Gerenciamento de inicialização assíncrona, animações fluidas e transição de rotas (Routing)
/// ══════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  String _loadingText = 'Loading';
  Timer? _dotTimer;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      // SoundService.playBackgroundMusic();
    });

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..addListener(() {
      setState(() {});
    });

    _progressController.forward().then((_) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          // Transição de rota direcionada para HomeScreen() para garantir o fluxo lógico de navegação (UX Navigation Flow)
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });

    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
          String dots = List.generate(_dotCount, (index) => '.').join();
          _loadingText = 'Loading$dots';
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadingText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}