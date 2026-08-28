import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/game_config.dart';

/// The composition rules that make the fixed desk shot read correctly. They
/// are cheap to break by nudging a single number, and expensive to notice.
void main() {
  test('the desk is the nearest thing to the lens', () {
    expect(GameConfig.priorityRoom, lessThan(GameConfig.priorityCustomer));
    expect(GameConfig.priorityCustomer, lessThan(GameConfig.priorityTable));
    expect(GameConfig.priorityTable, lessThan(GameConfig.priorityWorkspace));
  });

  test('the desk covers the station shot without side gaps', () {
    expect(GameConfig.tableMinWidth, GameConfig.viewWidth);
    expect(GameConfig.tableBottomY, GameConfig.viewHeight);
    expect(GameConfig.tableHeight, greaterThan(0));
  });

  test('the waist crop stays hidden behind the desk', () {
    expect(
      GameConfig.customerBottomY,
      greaterThan(GameConfig.tableWoodY),
      reason: 'she must be cut off by the wooden desktop, not hover above it',
    );
  });

  test('the chair crest clears the desk behind her shoulders', () {
    final chairTop = GameConfig.chairBottomY - GameConfig.chairHeight;
    expect(
      chairTop,
      lessThan(GameConfig.tableWoodY),
      reason: 'backrest must rise above the desktop so shop chairs read',
    );
    expect(
      chairTop,
      greaterThan(GameConfig.customerTopY),
      reason: 'crest stays below the top of her head cell',
    );
    expect(
      chairTop,
      lessThan(GameConfig.customerTopY + 220),
      reason: 'crest peeks by her shoulders, not as a second giant head',
    );
  });

  test('the chair sits behind her and in front of the room', () {
    expect(GameConfig.priorityRoom, lessThan(GameConfig.priorityChair));
    expect(GameConfig.priorityChair, lessThan(GameConfig.priorityCustomer));
    expect(
      GameConfig.chairBottomY,
      greaterThan(GameConfig.tableTopY),
      reason: 'the legs belong behind the desk, not floating above it',
    );
  });

  test('she walks in from off the left edge of the station shot', () {
    expect(GameConfig.customerEntryX, lessThan(GameConfig.customerSeatX));
    expect(
      GameConfig.customerEntryX,
      lessThan(GameConfig.stationX - GameConfig.viewWidth / 2),
      reason: 'she must start outside the frame, not pop in inside it',
    );
    expect(GameConfig.customerWalkSpeed, greaterThan(0));
  });

  test('the room is wide enough to swipe but never scrolls vertically', () {
    expect(GameConfig.worldWidth, greaterThan(GameConfig.viewWidth));
    expect(GameConfig.roomWidth, GameConfig.worldWidth);
    expect(GameConfig.worldHeight, GameConfig.viewHeight);
  });

  test('the camera rests on the station', () {
    expect(GameConfig.cameraHomeX, GameConfig.stationX);
    expect(GameConfig.cameraNailcareFocus.x, GameConfig.stationX);
  });
}
