"""Anatomically believable sit-down controller."""

from __future__ import annotations

from .walk_generator import SitPhase


SIT_ORDER = [
    SitPhase.FINAL_STEP,
    SitPhase.DECELERATE,
    SitPhase.FEET_REPOSITION,
    SitPhase.KNEES_BEND,
    SitPhase.HIPS_BACK,
    SitPhase.TORSO_BALANCE,
    SitPhase.DESCEND,
    SitPhase.SEAT_CONTACT,
    SitPhase.WEIGHT_SETTLE,
    SitPhase.FINAL_ADJUST,
    SitPhase.SEATED,
]


def sit_phase_at(t: float) -> SitPhase:
    """t in [0,1] across sit_down + seated."""
    t = max(0.0, min(0.999, t))
    idx = int(t * (len(SIT_ORDER) - 1))
    return SIT_ORDER[idx]


def sit_pose_description(phase: SitPhase) -> str:
    return {
        SitPhase.NONE: "standing",
        SitPhase.FINAL_STEP: (
            "last short walking step; speed low; preparing to stop at chair"
        ),
        SitPhase.DECELERATE: (
            "standing almost still; two feet nearing plant; weight centering"
        ),
        SitPhase.FEET_REPOSITION: (
            "both feet planted hip-width facing the chair/camera; balanced stand; "
            "NO walking stride"
        ),
        SitPhase.KNEES_BEND: (
            "knees begin bending; feet stay planted; hips start lowering slightly"
        ),
        SitPhase.HIPS_BACK: (
            "hips move BACKWARD toward the invisible chair seat; knees deeper; "
            "upper body leans slightly FORWARD for balance"
        ),
        SitPhase.TORSO_BALANCE: (
            "controlled squat toward seat height; torso angled slightly forward; "
            "hands near thighs for balance"
        ),
        SitPhase.DESCEND: (
            "smooth downward motion; hips approaching seat height; "
            "do NOT float; do NOT clip through seat"
        ),
        SitPhase.SEAT_CONTACT: (
            "hips make contact with invisible seat; thighs parallel; "
            "torso beginning to upright"
        ),
        SitPhase.WEIGHT_SETTLE: (
            "weight transfers onto chair; spine upright; feet still on floor; "
            "hands relaxing to lap"
        ),
        SitPhase.FINAL_ADJUST: (
            "subtle posture settle; shoulders down; calm smile; seated stable"
        ),
        SitPhase.SEATED: (
            "fully seated, relaxed and balanced, facing camera/table, "
            "hands in lap, final pose"
        ),
    }[phase]


def turn_pose_description(t: float) -> str:
    """t in [0,1] align_to_chair: profile-right → face chair/camera."""
    if t < 0.25:
        return (
            "standing still at chair, both feet planted, body facing RIGHT, "
            "profile 3/4, arms relaxed — stop pose after walk"
        )
    if t < 0.5:
        return (
            "in-place turn: hips and shoulders rotate toward camera; "
            "feet planted; head turning"
        )
    if t < 0.75:
        return (
            "body now three-quarter toward camera; feet adjusting; still standing"
        )
    return (
        "facing chair/camera, both feet planted, upright, ready to sit — "
        "NOT sitting yet"
    )
