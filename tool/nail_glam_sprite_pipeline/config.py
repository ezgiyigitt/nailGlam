"""Pipeline configuration — replaceable assets without rewriting motion logic."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = Path(__file__).resolve().parent / "output"


@dataclass
class AssetBundle:
    """Swap character / door / chair without touching planners."""

    character_identity: Path
    door: Path | None = None
    chair: Path | None = None
    # Forbidden: any path under these names is refused as motion reference.
    forbidden_motion_globs: tuple[str, ...] = (
        "*walk*",
        "*customer1_walk*",
        "*customer-walk*",
        "*_ref_customer/walk*",
    )


@dataclass
class CameraLock:
    """Fixed 3/4 gameplay camera for the entire sequence."""

    view: str = "three_quarter_side"
    travel_axis: str = "left_to_right"
    zoom: float = 1.0
    pan_x: float = 0.0
    pan_y: float = 0.0
    rotation_deg: float = 0.0
    focal_length: float = 50.0
    locked: bool = True


@dataclass
class ScaleHints:
    """Soft targets for the scene scale solver (validated visually later)."""

    character_height: float = 1.0
    door_height_min: float = 2.1
    door_height_max: float = 2.3
    chair_seat_height_ratio: float = 0.42  # of character height
    chair_width_ratio: float = 0.55
    door_opening_width_ratio: float = 0.85  # of character shoulder span * 2


@dataclass
class SequenceBudget:
    """Suggested frame ranges — pipeline picks within these for quality."""

    walk_to_door: tuple[int, int] = (8, 16)
    door_open: tuple[int, int] = (6, 12)
    walk_through_door: tuple[int, int] = (8, 14)
    walk_to_chair: tuple[int, int] = (12, 24)
    slow_down: tuple[int, int] = (6, 12)
    align_to_chair: tuple[int, int] = (6, 12)
    sit_down: tuple[int, int] = (12, 24)
    seated: tuple[int, int] = (4, 8)

    def pick(self, name: str, quality: str = "balanced") -> int:
        lo, hi = getattr(self, name)
        if quality == "draft":
            return lo
        if quality == "cinematic":
            return hi
        return (lo + hi) // 2


@dataclass
class PipelineConfig:
    fps: int = 24
    loop: bool = False
    quality: str = "balanced"  # draft | balanced | cinematic
    cell_width: int = 768
    cell_height: int = 1536
    sheet_padding: int = 24
    working_canvas: tuple[int, int] = (3840, 2160)
    transparent: bool = True
    reject_identity_delta: float = 0.28
    reject_pose_too_similar: float = 0.04
    reject_pose_jump: float = 0.55
    output_dir: Path = field(default_factory=lambda: DEFAULT_OUTPUT)
    assets: AssetBundle = field(
        default_factory=lambda: AssetBundle(
            character_identity=ROOT / "assets" / "images" / "character_look.png",
            door=ROOT / "assets" / "images" / "door.png",
            chair=ROOT / "assets" / "images" / "salon_chair.png",
        )
    )
    camera: CameraLock = field(default_factory=CameraLock)
    scale_hints: ScaleHints = field(default_factory=ScaleHints)
    budget: SequenceBudget = field(default_factory=SequenceBudget)

    sequence_names: tuple[str, ...] = (
        "walk_to_door",
        "door_open",
        "walk_through_door",
        "walk_to_chair",
        "slow_down",
        "align_to_chair",
        "sit_down",
        "seated",
    )
