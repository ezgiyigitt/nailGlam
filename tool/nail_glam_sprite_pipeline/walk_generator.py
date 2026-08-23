"""Biomechanical walk phases and temporal frame state."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from enum import Enum
import math


class WalkPhase(str, Enum):
    INITIAL_CONTACT = "initial_contact"
    LOADING_RESPONSE = "loading_response"
    MID_STANCE = "mid_stance"
    TERMINAL_STANCE = "terminal_stance"
    PRE_SWING = "pre_swing"
    INITIAL_SWING = "initial_swing"
    MID_SWING = "mid_swing"
    TERMINAL_SWING = "terminal_swing"


class SitPhase(str, Enum):
    NONE = "none"
    FINAL_STEP = "final_step"
    DECELERATE = "decelerate"
    FEET_REPOSITION = "feet_reposition"
    KNEES_BEND = "knees_bend"
    HIPS_BACK = "hips_back"
    TORSO_BALANCE = "torso_balance"
    DESCEND = "descend"
    SEAT_CONTACT = "seat_contact"
    WEIGHT_SETTLE = "weight_settle"
    FINAL_ADJUST = "final_adjust"
    SEATED = "seated"


GAIT_ORDER = list(WalkPhase)


@dataclass
class FrameState:
    frame_number: int
    time: float
    sequence: str
    character_position: float
    root_position: float
    head_position: float
    hip_position: float
    left_hand_position: float
    right_hand_position: float
    left_foot_position: float
    right_foot_position: float
    left_knee_angle: float
    right_knee_angle: float
    walk_phase: str
    movement_speed: float
    door_angle: float
    sit_phase: str
    camera_state: dict
    prompt_pose: str
    leading_leg: str = "right"

    def to_dict(self) -> dict:
        return asdict(self)


def gait_at(cycle_t: float) -> WalkPhase:
    """cycle_t in [0, 1) over one full stride (both legs)."""
    t = cycle_t % 1.0
    idx = int(t * len(GAIT_ORDER)) % len(GAIT_ORDER)
    return GAIT_ORDER[idx]


def contralateral_arms(leading_leg: str) -> tuple[str, str]:
    """Returns (left_arm, right_arm) as forward|back."""
    if leading_leg == "right":
        return "forward", "back"
    return "back", "forward"


def pose_description(phase: WalkPhase, leading_leg: str) -> str:
    left_arm, right_arm = contralateral_arms(leading_leg)
    other = "left" if leading_leg == "right" else "right"
    table = {
        WalkPhase.INITIAL_CONTACT: (
            f"{leading_leg} heel strikes forward on ground; {other} toes push off behind; "
            f"left arm {left_arm}, right arm {right_arm}"
        ),
        WalkPhase.LOADING_RESPONSE: (
            f"weight loads onto {leading_leg} planted foot; both knees soft; "
            f"{other} foot leaving ground a few inches; arms mid-swing"
        ),
        WalkPhase.MID_STANCE: (
            f"single-leg support on {leading_leg}; body upright over planted foot; "
            f"{other} foot swinging past ankle — modest knee bend, NOT a high march"
        ),
        WalkPhase.TERMINAL_STANCE: (
            f"{leading_leg} heel rising; hip extending; {other} foot swinging forward; "
            f"arms opposite to legs"
        ),
        WalkPhase.PRE_SWING: (
            f"{leading_leg} toe-off; weight shifting; prepare opposite contact"
        ),
        WalkPhase.INITIAL_SWING: (
            f"{leading_leg} leaves ground and begins swing; {other} now support; "
            f"soft knee, low clearance"
        ),
        WalkPhase.MID_SWING: (
            f"{leading_leg} foot passes support ankle at mid-shin height; "
            f"hips level; natural opposite arm swing"
        ),
        WalkPhase.TERMINAL_SWING: (
            f"{leading_leg} heel reaching forward to plant; {other} toes behind; "
            f"stride modest and salon-appropriate"
        ),
    }
    return table[phase]


def vertical_bob(cycle_t: float, amplitude: float = 0.012) -> float:
    return amplitude * abs(math.sin(cycle_t * math.pi * 2))
