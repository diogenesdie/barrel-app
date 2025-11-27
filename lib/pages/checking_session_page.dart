import 'package:flutter/material.dart';
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/biometric_utils.dart';
import 'package:smart_home/utils/session_utils.dart';

class CheckingSessionPage extends StatefulWidget {
  const CheckingSessionPage({super.key});

  @override
  State<CheckingSessionPage> createState() => _CheckingSessionPageState();
}

class _CheckingSessionPageState extends State<CheckingSessionPage> {
  bool _showRetryButton = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    final token = await SessionUtils.getToken();
    final expiresAt = await SessionUtils.getExpiresAt();

    // Simula pequeno loading enquanto valida sessão
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (token != null &&
        token.isNotEmpty &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt)) {
      
      final ok = await BiometricUtils.authenticate('login',
        reason: "Autentique-se para acessar o aplicativo",
      );
      if (ok) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
       
      // Mostra botão para tentar novamente a biometria
      setState(() {
        _showRetryButton = true;
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  Future<void> _retryBiometric() async {
    setState(() {
      _showRetryButton = false;
    });
    
    final ok = await BiometricUtils.authenticate('login',
      reason: "Autentique-se para acessar o aplicativo",
    );
    
    if (!mounted) return;
    
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _showRetryButton = true;
      });
    }
  }

  /// Mesmo gradiente usado no App/Login (primaryColorLight -> primaryColor)
  LinearGradient appGradient(BuildContext context) => LinearGradient(
        colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // FUNDO BRANCO
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // Logo
              Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),

              // BARREL com gradient igual ao login
              ShaderMask(
                shaderCallback: (bounds) => appGradient(context).createShader(bounds),
                child: const Text(
                  'BARREL',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                    color: Colors.white, // fica mascarado pelo ShaderMask
                  ),
                ),
              ),

              // SMART • HOME em cinza, com ponto usando o mesmo gradient
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'SMART',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: appGradient(context),
                    ),
                  ),
                  const Text(
                    'HOME',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Loader na cor primária (sem gradient), limpo sobre fundo branco
              if (!_showRetryButton)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ),

            // Botão para tentar novamente a biometria (fixo na parte inferior)
            if (_showRetryButton)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: _retryBiometric,
                    child: const Text(
                      'Usar senha do celular',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}