import 'package:flutter/material.dart';
import 'package:smart_home/providers/voice_command_provider.dart';
import 'package:provider/provider.dart';

class VoiceCommandScreen extends StatelessWidget {
  const VoiceCommandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<VoiceCommandProvider>(
        builder: (context, voiceProvider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (voiceProvider.isListening)
                  const Icon(Icons.mic, size: 100, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  voiceProvider.command.isNotEmpty
                      ? 'Comando: ${voiceProvider.command}'
                      : 'Diga "Hey Barrel"',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
