import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/controller/player_progress_controller.dart';
import 'package:nail_glam/model/salon_catalog.dart';
import 'package:nail_glam/view/shop_screen.dart';

void main() {
  testWidgets('shop is a swipeable showroom, not a list', (WidgetTester tester) async {
    final progress = PlayerProgressController.memory();
    progress.model.addCoins(800);
    await tester.pumpWidget(
      MaterialApp(home: ShopScreen(progressController: progress)),
    );

    expect(find.byKey(const Key('shop-showroom')), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.text(SalonCatalog.pinkChair.name), findsOneWidget);
    expect(find.byKey(Key('shop-buy-${SalonCatalog.pinkChair.id}')), findsOneWidget);
    expect(progress.owns(SalonCatalog.pinkChair.id), isFalse);

    await tester.tap(find.byKey(Key('shop-buy-${SalonCatalog.pinkChair.id}')));
    await tester.pump();
    expect(progress.owns(SalonCatalog.pinkChair.id), isTrue);
    expect(progress.coins, 300);
  });

  testWidgets('shop pages can be dragged with a mouse', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ShopScreen(progressController: PlayerProgressController.memory()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(Key('shop-buy-${SalonCatalog.pinkChair.id}')),
      findsOneWidget,
    );

    final center = tester.getCenter(find.byKey(const Key('shop-showroom')));
    final gesture = await tester.startGesture(
      center,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(-280, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      find.byKey(Key('shop-buy-${SalonCatalog.goldChair.id}')),
      findsOneWidget,
    );
  });
}
