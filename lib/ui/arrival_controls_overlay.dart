import 'package:flutter/material.dart';

/// Lightweight controls shown while the customer arrival scene is active.
class ArrivalControlsOverlay extends StatefulWidget {
  const ArrivalControlsOverlay({
    required this.onTogglePause,
    required this.onHome,
    super.key,
  });

  static const String id = 'arrivalControls';

  final bool Function() onTogglePause;
  final VoidCallback onHome;

  @override
  State<ArrivalControlsOverlay> createState() => _ArrivalControlsOverlayState();
}

class _ArrivalControlsOverlayState extends State<ArrivalControlsOverlay> {
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (_paused)
          const Positioned.fill(
            child: IgnorePointer(child: ColoredBox(color: Color(0x33000000))),
          ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _GameIconButton(
                  tooltip: _paused ? 'Devam et' : 'Durdur',
                  icon: _paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: const Color(0xFFFF80AD),
                  onPressed: () {
                    final paused = widget.onTogglePause();
                    setState(() => _paused = paused);
                  },
                ),
                const SizedBox(width: 12),
                _GameIconButton(
                  tooltip: 'Ana sayfa',
                  icon: Icons.home_rounded,
                  color: const Color(0xFF9F83EE),
                  onPressed: widget.onHome,
                ),
              ],
            ),
          ),
        ),
        if (_paused)
          const Center(
            child: IgnorePointer(
              child: Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                  shadows: <Shadow>[
                    Shadow(color: Color(0x66000000), blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GameIconButton extends StatelessWidget {
  const _GameIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 54,
        height: 59,
        decoration: BoxDecoration(
          color: Color.lerp(color, Colors.black, 0.25),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.topCenter,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 54,
              height: 53,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
