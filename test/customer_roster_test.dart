import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/customer_roster.dart';
import 'package:nail_glam/model/guest_care_kit.dart';
import 'package:nail_glam/model/nail_care_tools.dart';

void main() {
  test('customer1 is Lila, customer2 is Ezgi, customer3 is Zeynep', () {
    expect(CustomerRoster.customer1.id, 'customer1');
    expect(CustomerRoster.customer1.name, 'Lila');
    expect(CustomerRoster.lila.id, 'customer1');
    expect(CustomerRoster.customer2.id, 'customer2');
    expect(CustomerRoster.customer2.name, 'Ezgi');
    expect(CustomerRoster.ezgi.id, 'customer2');
    expect(CustomerRoster.customer3.id, 'customer3');
    expect(CustomerRoster.customer3.name, 'Zeynep');
    expect(CustomerRoster.zeynep.id, 'customer3');
  });

  test('visits rotate Lila then Ezgi then Zeynep', () {
    expect(CustomerRoster.forVisit(0).name, 'Lila');
    expect(CustomerRoster.forVisit(1).name, 'Ezgi');
    expect(CustomerRoster.forVisit(2).name, 'Zeynep');
    expect(CustomerRoster.forVisit(3).name, 'Lila');
  });

  test('each guest has her own art and dialogue', () {
    expect(
      CustomerRoster.customer1.emotionAsset,
      isNot(CustomerRoster.customer2.emotionAsset),
    );
    expect(
      CustomerRoster.customer3.emotionAsset,
      isNot(CustomerRoster.customer1.emotionAsset),
    );
    expect(CustomerRoster.customer1.introLine, contains('glam'));
    expect(CustomerRoster.customer2.introLine, contains('expensive'));
    expect(CustomerRoster.customer3.introLine, contains('Zeynep'));
    expect(CustomerRoster.customer2.fullDialogue.length, 5);
    expect(CustomerRoster.customer3.fullDialogue.length, 5);
    expect(CustomerRoster.customer3.walkFrameTime, 0.17);
    expect(CustomerRoster.customer3.turnFrameTime, 0.16);
    expect(CustomerRoster.customer3.sitFrameTime, 0.14);
    expect(CustomerRoster.customer1.walkFrameTime, isNull);
  });

  test('Zeynep uses dark wash and unified nail-clean art', () {
    final kit = GuestCareCatalog.forId(CustomerRoster.customer3.id);
    expect(kit.washAsset, AssetPaths.handWashDark);
    expect(kit.nailCleanAsset, AssetPaths.pinkyCleanDark);
    expect(kit.finalHandAsset, AssetPaths.finalHandDark);
    expect(kit.unifiedNailClean, isTrue);
    expect(kit.skipsCutAndPolish, isFalse);
    expect(kit.allowsCutAndPolish(NailDigit.pinky), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.ring), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.middle), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.pointer), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.thumb), isTrue);
    expect(kit.artFor(NailDigit.ring)?.cleanAsset, AssetPaths.ringCleanDark);
    expect(kit.artFor(NailDigit.middle)?.cleanAsset, AssetPaths.middleCleanDark);
    expect(kit.artFor(NailDigit.pointer)?.cleanAsset, AssetPaths.indexCleanDark);
    expect(kit.artFor(NailDigit.thumb)?.cleanAsset, AssetPaths.thumbCleanDark);
    expect(kit.shortNailAsset, AssetPaths.pinkyShortDark);
    expect(kit.polishMaskAsset, AssetPaths.pinkyNailMaskDark);
    expect(kit.finalHandAsset, AssetPaths.finalHandDark);
    expect(GuestCareCatalog.forId(CustomerRoster.customer1.id).unifiedNailClean, isTrue);
    expect(GuestCareCatalog.forId(CustomerRoster.customer1.id).finalHandAsset, AssetPaths.finalHandLight);
    expect(GuestCareCatalog.forId(CustomerRoster.customer2.id).finalHandAsset, AssetPaths.finalHandLight);
    expect(GuestCareCatalog.forId(CustomerRoster.customer2.id).skipsCutAndPolish, isFalse);
  });

  test('Lila and Ezgi share cartoon light nail sheets for every digit', () {
    final kit = GuestCareCatalog.forId(CustomerRoster.customer1.id);
    expect(identical(kit, GuestCareCatalog.forId(CustomerRoster.customer2.id)), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.pinky), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.ring), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.middle), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.pointer), isTrue);
    expect(kit.allowsCutAndPolish(NailDigit.thumb), isTrue);
    expect(kit.artFor(NailDigit.pinky)?.cleanAsset, AssetPaths.pinkyCleanLight);
    expect(kit.artFor(NailDigit.ring)?.cleanAsset, AssetPaths.middleCleanLight);
    expect(kit.artFor(NailDigit.middle)?.cleanAsset, AssetPaths.middleCleanLight);
    expect(kit.artFor(NailDigit.pointer)?.cleanAsset, AssetPaths.middleCleanLight);
    expect(kit.artFor(NailDigit.thumb)?.cleanAsset, AssetPaths.thumbCleanLight);
  });
}
