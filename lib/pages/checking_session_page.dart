import 'package:flutter/material.dart';
import 'package:smart_home/utils/session_utils.dart';

class CheckingSessionPage extends StatefulWidget {
  const CheckingSessionPage({super.key});

  @override
  State<CheckingSessionPage> createState() => _CheckingSessionPageState();
}

class _CheckingSessionPageState extends State<CheckingSessionPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    print("Iniciando verificação de sessão...");

    final token = await SessionUtils.getToken();
    final expiresAt = await SessionUtils.getExpiresAt();

    print("Token: $token");
    print("ExpiresAt: $expiresAt");

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');

    if (token != null && token.isNotEmpty && expiresAt != null && DateTime.now().isBefore(expiresAt)) {
      print("Sessão válida, indo para /home");
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      print("Sessão inválida, indo para /auth");
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grad = LinearGradient(
      colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: Center(
          child: ScaleTransition(
            scale: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                ShaderMask(
                  shaderCallback: (bounds) => grad.createShader(bounds),
                  child: const Text(
                    "BARREL",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Smart Home",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
