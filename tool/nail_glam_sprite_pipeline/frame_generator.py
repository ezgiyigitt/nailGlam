"""Frame generation interface.

Walking motion is planned procedurally — NEVER loaded from old walk sheets.
Image backends only receive character identity + pose text.
"""

from __future__ import annotations

import json
from abc import ABC, abstractmethod
from pathlib import Path

from PIL import Image, ImageDraw

from .character_identity import CharacterIdentity, assert_not_motion_reference
from .exporters import build_frame_prompt
from .motion_planner import MotionPlan
from .walk_generator import FrameState


class FrameBackend(ABC):
    @abstractmethod
    def generate(self, prompt: str, out_path: Path, identity_path: Path) -> Path:
        raise NotImplementedError


class PromptOnlyBackend(FrameBackend):
    """Writes prompts for external AI (Cursor GenerateImage, API, etc.)."""

    def generate(self, prompt: str, out_path: Path, identity_path: Path) -> Path:
        assert_not_motion_reference(identity_path)
        out_path = out_path.with_suffix(".txt")
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(
            json.dumps(
                {
                    "identity_reference": str(identity_path),
                    "forbidden": "Do not use any walking sprite sheet as reference",
                    "prompt": prompt,
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        return out_path


class PlaceholderBackend(FrameBackend):
    """Deterministic stick-figure placeholders for CI / layout tests."""

    def generate(self, prompt: str, out_path: Path, identity_path: Path) -> Path:
        assert_not_motion_reference(identity_path)
        # Encode pose hash into limb angles so consecutive frames differ.
        h = sum(ord(c) for c in prompt) % 360
        im = Image.new("RGBA", (768, 1536), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, ground = 384, 1450
        # Body
        d.ellipse([cx - 40, 180, cx + 40, 260], fill=(180, 120, 90, 255))
        d.rectangle([cx - 50, 260, cx + 50, 700], fill=(220, 120, 150, 255))
        # Legs alternate by hash
        swing = (h % 50) - 25
        d.line([(cx - 20, 700), (cx - 40 - swing, ground)], fill=(240, 240, 240, 255), width=18)
        d.line([(cx + 20, 700), (cx + 40 + swing, ground)], fill=(240, 240, 240, 255), width=18)
        d.line([(cx - 50, 400), (cx - 120, 550 + swing)], fill=(220, 120, 150, 255), width=14)
        d.line([(cx + 50, 400), (cx + 120, 550 - swing)], fill=(220, 120, 150, 255), width=14)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        im.save(out_path)
        return out_path


def build_strip_jobs(plan: MotionPlan, identity: CharacterIdentity, per_strip: int = 4) -> list[dict]:
    """Group frames into multi-pose strip prompts for batch AI generation."""
    jobs = []
    frames = plan.frames
    for start in range(0, len(frames), per_strip):
        chunk = frames[start : start + per_strip]
        poses = []
        for j, fr in enumerate(chunk):
            poses.append(f"Pose {j + 1}: {fr.prompt_pose}")
        prompt = (
            f"{identity.prompt_lock}\n\n"
            f"A horizontal spritesheet of EXACTLY {len(chunk)} full-body poses "
            f"of the SAME woman, wide empty black gaps between figures, "
            f"identical height, shared foot ground line. "
            f"Fixed 3/4 camera. Solid pure black background. "
            f"No chair, table, UI, text, watermark. "
            f"Door may appear only as a simple rigid hinged leaf if the pose mentions door.\n\n"
            + "\n".join(poses)
            + "\n\nEach pose must be a genuinely different movement phase. "
            "Natural contralateral walk when walking. No duplicate poses."
        )
        jobs.append(
            {
                "start_frame": chunk[0].frame_number,
                "end_frame": chunk[-1].frame_number,
                "sequences": [f.sequence for f in chunk],
                "identity_reference_only": str(identity.path),
                "forbidden_references": [
                    "any prior walking sprite sheet",
                    "customer-walk-v1",
                    "customer1_walk",
                ],
                "prompt": prompt,
            }
        )
    return jobs


def write_generation_jobs(jobs: list[dict], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(jobs, indent=2), encoding="utf-8")


def prompts_for_plan(
    plan: MotionPlan, identity: CharacterIdentity
) -> list[tuple[FrameState, str]]:
    return [
        (fr, build_frame_prompt(identity.prompt_lock, fr.prompt_pose, fr))
        for fr in plan.frames
    ]
