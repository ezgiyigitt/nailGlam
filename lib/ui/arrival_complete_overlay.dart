import 'package:flutter/material.dart';

/// Shown once the camera has settled on the nail-care close-up.
///
/// Part 2 replaces this with the manicure tools; for now it exists so the
/// arrival loop can be replayed without restarting the app.
class ArrivalCompleteOverlay extends StatelessWidget {
  const ArrivalCompleteOverlay({required this.onReplay, super.key});

  static const String id = 'arrivalComplete';

  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 36),
          child: Material(
            color: const Color(0xCC5B3742),
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onReplay,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Next customer',
                      style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
