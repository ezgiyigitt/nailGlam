import 'package:flutter/material.dart';

import '../game/config/asset_paths.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

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
          ),
          const ColoredBox(color: Color(0x33FFF2FA)),
          SafeArea(
            minimum: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: _BackButton(onPressed: () => Navigator.pop(context)),
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFF8FC),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x339A5180),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'HOW TO PLAY',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            color: Color(0xFF9B4C91),
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
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
            decoration: const BoxDecoration(
              color: Color(0xFFFFD3E7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFD65591)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: Color(0xFF765368),
                fontSize: 16,
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
      color: const Color(0xFFAF72E7),
      shape: const CircleBorder(),
      elevation: 5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 54,
          height: 54,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
