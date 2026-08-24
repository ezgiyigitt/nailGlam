import 'package:flutter/material.dart';

import '../game/audio/game_audio.dart';
import '../game/config/asset_paths.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const Color _pink = Color(0xFFFF6BA8);
  static const Color _pinkDeep = Color(0xFFE84F8F);
  static const Color _cream = Color(0xFFFFF6F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/${AssetPaths.menuBackground}',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          const ColoredBox(color: Color(0x28FFFFFF)),
          SafeArea(
            minimum: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: _BackButton(
                    onPressed: () {
                      GameAudio.instance.tap();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                    decoration: BoxDecoration(
                      color: const Color(0xF5FFF8FC),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: _cream, width: 5),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x44C2185B),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'HOW TO PLAY',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            color: _pinkDeep,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(height: 22),
                        _Instruction(
                          icon: Icons.directions_walk_rounded,
                          text: 'Welcome each customer to your nail salon.',
                        ),
                        _Instruction(
                          icon: Icons.back_hand_rounded,
                          text: 'Follow the steps and care for every nail.',
                        ),
                        _Instruction(
                          icon: Icons.auto_awesome_rounded,
                          text: 'Create a beautiful result and make her happy!',
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFFFF9BC4), Color(0xFFFF6BA8)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFF6F0), width: 3),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33C2185B),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                color: Color(0xFF8A4A68),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HowToPlayScreen._pink,
      shape: const CircleBorder(
        side: BorderSide(color: HowToPlayScreen._cream, width: 3),
      ),
      elevation: 5,
      shadowColor: const Color(0x55C2185B),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
