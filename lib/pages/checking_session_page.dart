import 'package:flutter/material.dart';
import 'package:smart_home/utils/session_utils.dart';

class CheckingSessionPage extends StatefulWidget {
  const CheckingSessionPage({super.key});

  @override
  State<CheckingSessionPage> createState() => _CheckingSessionPageState();
}

class _CheckingSessionPageState extends State<CheckingSessionPage>
    with TickerProviderStateMixin {
  late AnimationController _colorController;

  @override
  void initState() {
    super.initState();

    // Controla a troca suave de cores do fundo
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final token = await SessionUtils.getToken();
    final expiresAt = await SessionUtils.getExpiresAt();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (token != null &&
        token.isNotEmpty &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt)) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color1 = Theme.of(context).primaryColor;
    final color2 = Theme.of(context).colorScheme.secondary;
    final color3 = Theme.of(context).primaryColorLight;

    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        final t = _colorController.value;

        final animatedGradient = LinearGradient(
          colors: [
            Color.lerp(color1, color2, t)!,
            Color.lerp(color2, color3, t)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: animatedGradient),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "BARREL",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Smart Home",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
