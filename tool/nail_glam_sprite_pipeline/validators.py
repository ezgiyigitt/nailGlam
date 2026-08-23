"""Temporal / identity / camera / continuity validators."""

from __future__ import annotations

from dataclasses import dataclass, field

from PIL import Image
import numpy as np

from .character_identity import CharacterIdentity, identity_delta
from .config import CameraLock, PipelineConfig
from .motion_planner import MotionPlan


@dataclass
class ValidationReport:
    ok: bool
    issues: list[str] = field(default_factory=list)
    continuity_scores: list[float] = field(default_factory=list)

    def fail(self, msg: str) -> None:
        self.ok = False
        self.issues.append(msg)


def validate_plan(plan: MotionPlan, cfg: PipelineConfig) -> ValidationReport:
    report = ValidationReport(ok=True)
    if plan.frame_count < 24:
        report.fail(f"too few frames ({plan.frame_count}) for continuous motion")
    if cfg.camera.locked is False:
        report.fail("camera lock disabled")

    prev = None
    for fr in plan.frames:
        cam = fr.camera_state
        if cam.get("zoom") != cfg.camera.zoom:
            report.fail(f"frame {fr.frame_number}: camera zoom changed")
        if cam.get("locked") is not True:
            report.fail(f"frame {fr.frame_number}: camera unlocked")
        if prev is not None:
            dx = abs(fr.character_position - prev.character_position)
            # Walking frames should move; seated should not teleport.
            if fr.sequence in {"seated", "align_to_chair", "sit_down"} and dx > 0.05:
                report.fail(f"frame {fr.frame_number}: teleport during {fr.sequence}")
            if (
                fr.sequence.startswith("walk")
                and dx < 1e-6
                and fr.movement_speed > 0.2
            ):
                report.fail(f"frame {fr.frame_number}: walk frame with zero travel")
            if fr.prompt_pose == prev.prompt_pose:
                report.fail(f"frame {fr.frame_number}: duplicate pose description")
        prev = fr

    # Chronology
    for i, fr in enumerate(plan.frames):
        if fr.frame_number != i:
            report.fail("frame_number not chronological")
            break
    if plan.frames[-1].sit_phase != "seated":
        report.fail("last frame is not seated")
    if plan.frames[0].sequence != "walk_to_door":
        report.fail("first frame is not walk_to_door")
    return report


def frame_difference(a: Image.Image, b: Image.Image) -> float:
    aa = np.asarray(a.convert("RGBA").resize((128, 256)))
    bb = np.asarray(b.convert("RGBA").resize((128, 256)))
    mask = (aa[:, :, 3] > 16) | (bb[:, :, 3] > 16)
    if not mask.any():
        return 0.0
    diff = np.abs(aa[:, :, :3].astype(np.float32) - bb[:, :, :3].astype(np.float32))
    return float(diff[mask].mean() / 255.0)


def validate_rendered_pair(
    prev: Image.Image,
    curr: Image.Image,
    identity: CharacterIdentity,
    cfg: PipelineConfig,
    frame_index: int,
) -> list[str]:
    issues: list[str] = []
    d_id = identity_delta(curr, identity)
    if d_id > cfg.reject_identity_delta:
        issues.append(
            f"frame {frame_index}: identity drift {d_id:.3f} > {cfg.reject_identity_delta}"
        )
    d = frame_difference(prev, curr)
    if d < cfg.reject_pose_too_similar:
        issues.append(f"frame {frame_index}: nearly duplicate pose ({d:.3f})")
    if d > cfg.reject_pose_jump:
        issues.append(f"frame {frame_index}: pose jump ({d:.3f})")
    return issues


def validate_camera_lock(cam: CameraLock) -> list[str]:
    issues = []
    if not cam.locked:
        issues.append("camera not locked")
    if cam.zoom != 1.0:
        issues.append("camera zoom must stay 1.0 for export consistency")
    return issues
