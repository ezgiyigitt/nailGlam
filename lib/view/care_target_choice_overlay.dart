import 'package:flutter/material.dart';

/// Shown right as the manicure plate opens: pick hand or foot care before
/// [NailCareController] starts its wash/nail-clean state machine.
class CareTargetChoiceOverlay extends StatelessWidget {
  const CareTargetChoiceOverlay({
    required this.onChooseHand,
    required this.onChooseFoot,
    super.key,
  });

  static const String id = 'careTargetChoice';

  final VoidCallback onChooseHand;
  final VoidCallback onChooseFoot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const ModalBarrier(dismissible: false, color: Color(0x99000000)),
        Center(
          child: Material(
            key: const Key('care-target-choice'),
            color: const Color(0xF7FFF8FC),
            elevation: 18,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A4B63),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _ChoiceCard(
                        key: const Key('care-target-hand'),
                        label: 'Manicure',
                        icon: Icons.back_hand_rounded,
                        onTap: onChooseHand,
                      ),
                      const SizedBox(width: 14),
                      _ChoiceCard(
                        key: const Key('care-target-foot'),
                        label: 'Pedicure',
                        icon: Icons.directions_walk_rounded,
                        onTap: onChooseFoot,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEC4D8), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: const Color(0xFFD6618A)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A6070),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
