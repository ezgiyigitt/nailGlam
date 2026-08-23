"""Motion planner — continuous temporal state for the full arrival."""

from __future__ import annotations

from dataclasses import dataclass

from .config import CameraLock, PipelineConfig
from .door_controller import door_angle_for_progress, door_hold_open, door_prompt
from .scene_scale import SceneScale
from .sit_controller import sit_phase_at, sit_pose_description, turn_pose_description
from .walk_generator import (
    FrameState,
    SitPhase,
    gait_at,
    pose_description,
    vertical_bob,
)


@dataclass
class MotionPlan:
    frames: list[FrameState]
    fps: int
    sequence: list[str]

    @property
    def frame_count(self) -> int:
        return len(self.frames)


def _camera_dict(cam: CameraLock) -> dict:
    return {
        "view": cam.view,
        "zoom": cam.zoom,
        "pan_x": cam.pan_x,
        "pan_y": cam.pan_y,
        "rotation_deg": cam.rotation_deg,
        "locked": cam.locked,
    }


def plan_motion(cfg: PipelineConfig, scale: SceneScale) -> MotionPlan:
    fps = cfg.fps
    cam = _camera_dict(cfg.camera)
    frames: list[FrameState] = []
    t = 0.0
    dt = 1.0 / fps
    x = 0.0
    door_angle = 0.0
    stride_len = 0.55 * scale.character_height
    # One gait cycle distance ≈ stride_len * 2 (left + right)
    cycle_dist = stride_len * 2.0

    def add(
        sequence: str,
        *,
        x_pos: float,
        speed: float,
        door: float,
        walk_phase: str,
        sit_phase: str,
        pose: str,
        leading: str,
        bob: float = 0.0,
    ) -> None:
        nonlocal t
        n = len(frames)
        hip = 0.55 + bob
        head = 0.95 + bob * 0.3
        frames.append(
            FrameState(
                frame_number=n,
                time=t,
                sequence=sequence,
                character_position=x_pos,
                root_position=x_pos,
                head_position=head,
                hip_position=hip,
                left_hand_position=0.0,
                right_hand_position=0.0,
                left_foot_position=0.0,
                right_foot_position=0.0,
                left_knee_angle=0.0,
                right_knee_angle=0.0,
                walk_phase=walk_phase,
                movement_speed=speed,
                door_angle=door,
                sit_phase=sit_phase,
                camera_state=dict(cam),
                prompt_pose=pose,
                leading_leg=leading,
            )
        )
        t += dt

    # --- walk_to_door ---
    n = cfg.budget.pick("walk_to_door", cfg.quality)
    for i in range(n):
        u = (i + 1) / n
        x = u * 0.35 * scale.walk_distance
        cycle_t = (x / cycle_dist) % 1.0
        phase = gait_at(cycle_t)
        leading = "right" if cycle_t < 0.5 else "left"
        add(
            "walk_to_door",
            x_pos=x,
            speed=1.0,
            door=0.0,
            walk_phase=phase.value,
            sit_phase=SitPhase.NONE.value,
            pose=(
                pose_description(phase, leading)
                + f". gait_t={cycle_t:.3f}. "
                + door_prompt(0.0)
            ),
            leading=leading,
            bob=vertical_bob(cycle_t),
        )

    # --- door_open ---
    n = cfg.budget.pick("door_open", cfg.quality)
    start_x = x
    for i in range(n):
        u = (i + 1) / n
        door_angle = door_angle_for_progress(u)
        x = start_x + (0.08 * scale.walk_distance) * u
        cycle_t = (x / cycle_dist) % 1.0
        phase = gait_at(cycle_t)
        leading = "right" if cycle_t < 0.5 else "left"
        add(
            "door_open",
            x_pos=x,
            speed=0.85,
            door=door_angle,
            walk_phase=phase.value,
            sit_phase=SitPhase.NONE.value,
            pose=(
                pose_description(phase, leading)
                + f". gait_t={cycle_t:.3f}. "
                + door_prompt(door_angle)
            ),
            leading=leading,
            bob=vertical_bob(cycle_t),
        )

    # --- walk_through_door ---
    n = cfg.budget.pick("walk_through_door", cfg.quality)
    door_angle = door_hold_open()
    start_x = x
    for i in range(n):
        u = (i + 1) / n
        x = start_x + (0.45 * scale.walk_distance) * u
        cycle_t = (x / cycle_dist) % 1.0
        phase = gait_at(cycle_t)
        leading = "right" if cycle_t < 0.5 else "left"
        add(
            "walk_through_door",
            x_pos=x,
            speed=1.0,
            door=door_angle,
            walk_phase=phase.value,
            sit_phase=SitPhase.NONE.value,
            pose=(
                pose_description(phase, leading)
                + f". Clearing doorway. gait_t={cycle_t:.3f}. "
                + door_prompt(door_angle)
            ),
            leading=leading,
            bob=vertical_bob(cycle_t),
        )

    # --- walk_to_chair ---
    n = cfg.budget.pick("walk_to_chair", cfg.quality)
    start_x = x
    target = scale.stop_x * 0.82
    for i in range(n):
        u = (i + 1) / n
        x = start_x + (target - start_x) * u
        cycle_t = (x / cycle_dist) % 1.0
        phase = gait_at(cycle_t)
        leading = "right" if cycle_t < 0.5 else "left"
        add(
            "walk_to_chair",
            x_pos=x,
            speed=1.0,
            door=door_angle,
            walk_phase=phase.value,
            sit_phase=SitPhase.NONE.value,
            pose=(
                pose_description(phase, leading)
                + f". Walking inside salon toward chair. gait_t={cycle_t:.3f}."
            ),
            leading=leading,
            bob=vertical_bob(cycle_t),
        )

    # --- slow_down ---
    n = cfg.budget.pick("slow_down", cfg.quality)
    start_x = x
    for i in range(n):
        u = (i + 1) / n
        speed = 1.0 - 0.85 * u
        x = start_x + (scale.stop_x - start_x) * u
        cycle_t = (x / cycle_dist) % 1.0
        phase = gait_at(cycle_t)
        leading = "right" if cycle_t < 0.5 else "left"
        add(
            "slow_down",
            x_pos=x,
            speed=speed,
            door=door_angle,
            walk_phase=phase.value,
            sit_phase=SitPhase.DECELERATE.value,
            pose=(
                pose_description(phase, leading)
                + f". Gradual deceleration speed={speed:.2f}; shorter stride. "
                f"gait_t={cycle_t:.3f}."
            ),
            leading=leading,
            bob=vertical_bob(cycle_t) * (1 - u),
        )
    x = scale.stop_x

    # --- align_to_chair (in place — x stays at stop) ---
    n = cfg.budget.pick("align_to_chair", cfg.quality)
    for i in range(n):
        u = i / max(n - 1, 1)
        add(
            "align_to_chair",
            x_pos=x,
            speed=0.0,
            door=door_angle,
            walk_phase="none",
            sit_phase=SitPhase.FEET_REPOSITION.value,
            pose=turn_pose_description(u) + f" turn_t={u:.3f}.",
            leading="none",
            bob=0.0,
        )

    # --- sit_down (same root x as stop — no teleport) ---
    n = cfg.budget.pick("sit_down", cfg.quality)
    x = scale.stop_x
    for i in range(n):
        u = i / max(n - 1, 1)
        phase = sit_phase_at(u * 0.9)
        add(
            "sit_down",
            x_pos=x,
            speed=0.0,
            door=door_angle,
            walk_phase="none",
            sit_phase=phase.value,
            pose=(
                sit_pose_description(phase)
                + f". sit_t={u:.3f}. NO chair drawn — chair is a world prop."
            ),
            leading="none",
            bob=0.0,
        )

    # --- seated ---
    n = cfg.budget.pick("seated", cfg.quality)
    for i in range(n):
        u = i / max(n - 1, 1)
        add(
            "seated",
            x_pos=x,
            speed=0.0,
            door=door_angle,
            walk_phase="none",
            sit_phase=SitPhase.SEATED.value,
            pose=sit_pose_description(SitPhase.SEATED) + f" settle_t={u:.3f}.",
            leading="none",
        )

    return MotionPlan(
        frames=frames,
        fps=fps,
        sequence=list(cfg.sequence_names),
    )
