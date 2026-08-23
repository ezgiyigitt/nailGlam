"""PNG sheet + JSON metadata exporters."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from .motion_planner import MotionPlan
from .packer import AtlasEntry


def export_metadata(
    plan: MotionPlan,
    atlas: list[AtlasEntry],
    out_path: Path,
    *,
    sheet_name: str,
    scale_notes: list[str],
    validation_issues: list[str],
) -> None:
    payload = {
        "fps": plan.fps,
        "frameCount": plan.frame_count,
        "loop": False,
        "sequence": plan.sequence,
        "sheet": sheet_name,
        "scaleNotes": scale_notes,
        "validationIssues": validation_issues,
        "frames": [
            {
                **fr.to_dict(),
                "atlas": {
                    "x": atlas[i].x if i < len(atlas) else 0,
                    "y": atlas[i].y if i < len(atlas) else 0,
                    "w": atlas[i].w if i < len(atlas) else 0,
                    "h": atlas[i].h if i < len(atlas) else 0,
                },
            }
            for i, fr in enumerate(plan.frames)
        ],
        "timing": [
            {"frame": fr.frame_number, "time": fr.time, "sequence": fr.sequence}
            for fr in plan.frames
        ],
        "policy": {
            "noOldWalkSpritesAsMotionReference": True,
            "identityLock": True,
            "cameraFixed": True,
            "continuousNonLooping": True,
        },
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def export_prompts(plan: MotionPlan, out_path: Path, identity_lock: str) -> None:
    lines = []
    for fr in plan.frames:
        lines.append(
            {
                "frame": fr.frame_number,
                "sequence": fr.sequence,
                "prompt": build_frame_prompt(identity_lock, fr.prompt_pose, fr),
            }
        )
    out_path.write_text(json.dumps(lines, indent=2), encoding="utf-8")


def build_frame_prompt(identity_lock: str, pose: str, fr) -> str:
    return (
        f"{identity_lock}\n\n"
        f"Exactly ONE full-body figure. Fixed 3/4 side gameplay camera, "
        f"character facing/traveling RIGHT unless pose says otherwise. "
        f"Isolated on solid pure black. No UI, text, watermark, logo. "
        f"No background salon room. Do NOT draw a chair or table unless "
        f"the pose explicitly needs door context as a rigid prop silhouette.\n\n"
        f"POSE / ACTION: {pose}\n\n"
        f"Metadata: sequence={fr.sequence} walk_phase={fr.walk_phase} "
        f"sit_phase={fr.sit_phase} door_angle={fr.door_angle:.1f} "
        f"speed={fr.movement_speed:.2f}.\n"
        f"Feet on one shared invisible ground line. Same height every frame. "
        f"Clean sharp silhouette, no white halo."
    )


def write_flame_atlas_snippet(atlas: list[AtlasEntry], cell_w: int, cell_h: int) -> str:
    origins = ",\n".join(
        f"      Vector2({e.x}.0, {e.y}.0)" for e in atlas
    )
    return (
        f"// Auto-generated — continuous arrival sheet\n"
        f"frameSize: Vector2({cell_w}, {cell_h}),\n"
        f"framePositions: <Vector2>[\n{origins}\n    ],\n"
    )
