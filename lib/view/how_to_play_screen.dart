import 'package:flutter/material.dart';

import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/model/asset_paths.dart';

/// Optional menu tutorial — Apple HIG: short, skippable, one idea per page.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  static const Color pink = Color(0xFFFF6BA8);
  static const Color pinkDeep = Color(0xFFE84F8F);
  static const Color cream = Color(0xFFFFF6F0);

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayPage {
  const _HowToPlayPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  static const List<_HowToPlayPage> _pages = <_HowToPlayPage>[
    _HowToPlayPage(
      icon: Icons.soap_rounded,
      title: 'Wash',
      body: 'Wash the hand first.',
    ),
    _HowToPlayPage(
      icon: Icons.water_drop_rounded,
      title: 'Clean',
      body: 'Spray, then wipe each nail.',
    ),
    _HowToPlayPage(
      icon: Icons.content_cut_rounded,
      title: 'Clip',
      body: 'Clip the tip when it is ready.',
    ),
    _HowToPlayPage(
      icon: Icons.brush_rounded,
      title: 'Polish',
      body: 'Paint with polish and tap Next.',
    ),
  ];

  final PageController _pager = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _close() {
    GameAudio.instance.tap();
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  void _next() {
    GameAudio.instance.tap();
    if (_index >= _pages.length - 1) {
      _close();
      return;
    }
    _pager.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index >= _pages.length - 1;
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
          const ColoredBox(color: Color(0x77FFFFFF)),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      semanticLabel: 'Back',
                      onPressed: _close,
                    ),
                    const Expanded(
                      child: Text(
                        'HOW TO PLAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          color: HowToPlayScreen.pinkDeep,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    _TextChip(
                      key: const Key('how-to-play-skip'),
                      label: 'Skip',
                      onPressed: _close,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView.builder(
                    key: const Key('how-to-play-pager'),
                    controller: _pager,
                    itemCount: _pages.length,
                    onPageChanged: (int i) => setState(() => _index = i),
                    itemBuilder: (BuildContext context, int i) {
                      final page = _pages[i];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _PageCard(page: page),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (var i = 0; i < _pages.length; i++)
                      _Dot(active: i == _index),
                  ],
                ),
                const SizedBox(height: 16),
                _PrimaryButton(
                  key: last
                      ? const Key('how-to-play-got-it')
                      : const Key('how-to-play-next'),
                  label: last ? 'Got it' : 'Next',
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({required this.page});

  final _HowToPlayPage page;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF7FFF8FC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: HowToPlayScreen.cream, width: 5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x44C2185B),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0x33FF6BA8),
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, size: 48, color: HowToPlayScreen.pinkDeep),
            ),
            const SizedBox(height: 28),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                color: HowToPlayScreen.pinkDeep,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                color: Color(0xFF7A3D5C),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: active ? 22 : 9,
      height: 9,
      decoration: BoxDecoration(
        color: active ? HowToPlayScreen.pink : const Color(0x55E84F8F),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HowToPlayScreen.pink,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: const Color(0x55C2185B),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HowToPlayScreen.pink,
      shape: const CircleBorder(
        side: BorderSide(color: HowToPlayScreen.cream, width: 3),
      ),
      elevation: 5,
      shadowColor: const Color(0x55C2185B),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: Colors.white,
            semanticLabel: semanticLabel,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  const _TextChip({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2FFF8FC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              color: HowToPlayScreen.pinkDeep,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
