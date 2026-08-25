import 'package:flame/components.dart';
import 'package:nail_glam/model/asset_paths.dart';

/// One visiting client. Art + dialogue travel with the profile.
class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.walkAsset,
    required this.turnAsset,
    required this.sitAsset,
    required this.emotionAsset,
    required this.introLine,
    required this.dialogueLines,
    this.walkFrameTime,
    this.turnFrameTime,
    this.sitFrameTime,
    this.walkFrameAlign,
    this.turnFrameAlign,
    this.sitFrameAlign,
  });

  final String id;
  final String name;
  final String walkAsset;
  final String turnAsset;
  final String sitAsset;
  final String emotionAsset;
  final String introLine;

    /// Seconds per walk-cycle cell. Null uses the shared salon walk timing.
    final double? walkFrameTime;

    /// Seconds per turn/sit cell. Null uses shared salon timing.
    final double? turnFrameTime;
    final double? sitFrameTime;

  /// Optional per-frame pixel shifts to correct art misalignment.
  final List<Vector2>? walkFrameAlign;
  final List<Vector2>? turnFrameAlign;
  final List<Vector2>? sitFrameAlign;

  /// Lines after [introLine], shown in the thought bubble in order.
  final List<String> dialogueLines;

  List<String> get fullDialogue => <String>[introLine, ...dialogueLines];
}

/// Appointment book. Visit n picks guest n % roster length.
abstract final class CustomerRoster {
  static const CustomerProfile customer1 = CustomerProfile(
    id: 'customer1',
    name: 'Lila',
    walkAsset: AssetPaths.customerWalk,
    turnAsset: AssetPaths.customerTurn,
    sitAsset: AssetPaths.customerSit,
    emotionAsset: AssetPaths.customerEmotion,
    introLine: "I'm ready for some glam! 💕",
    dialogueLines: <String>[
      "First, let's clean my nails!",
      "Now let's smooth and shape them!",
      'Time for some beautiful color! ✨',
      "Let's make them fabulous! 💅",
    ],
  );

  static const CustomerProfile customer2 = CustomerProfile(
    id: 'customer2',
    name: 'Ezgi',
    walkAsset: AssetPaths.customer2Walk,
    turnAsset: AssetPaths.customer2Turn,
    sitAsset: AssetPaths.customer2Sit,
    emotionAsset: AssetPaths.customer2Emotion,
    introLine: "Hey — make my nails look expensive.",
    dialogueLines: <String>[
      'Start with a clean base.',
      'Shape them sharp, not soft.',
      'I want a deep, bold color.',
      "Don't rush the finish. ✨",
    ],
  );

  static const CustomerProfile customer3 = CustomerProfile(
    id: 'customer3',
    name: 'Zeynep',
    walkAsset: AssetPaths.customer3Walk,
    turnAsset: AssetPaths.customer3Turn,
    sitAsset: AssetPaths.customer3Sit,
    emotionAsset: AssetPaths.customer3Emotion,
    introLine: "Hi — I'm Zeynep. Let's start fresh.",
    walkFrameTime: 0.17,
    turnFrameTime: 0.16,
    sitFrameTime: 0.14,
    dialogueLines: <String>[
      'First, a gentle hand wash.',
      'Then clean each nail, one by one.',
      "Slow and careful — that's all for today.",
      'Thank you! ✨',
    ],
  );

  static const CustomerProfile lila = customer1;
  static const CustomerProfile ezgi = customer2;
  static const CustomerProfile zeynep = customer3;

  static const List<CustomerProfile> all = <CustomerProfile>[
    customer1,
    customer2,
    customer3,
  ];

  static CustomerProfile forVisit(int visit) {
    if (all.isEmpty) {
      return customer1;
    }
    final index = visit % all.length;
    return all[index < 0 ? 0 : index];
  }
}
