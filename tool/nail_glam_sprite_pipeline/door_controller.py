"""Door as a rigid hinged object — angle only, no morphing."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class DoorState:
    angle_deg: float  # 0 = closed, ~75 = open toward camera/away
    hinge_fixed: bool = True
    rigid: bool = True


def door_angle_for_progress(t: float, open_max: float = 78.0) -> float:
    """t in [0,1] during door_open sequence. Ease-out open."""
    t = max(0.0, min(1.0, t))
    eased = 1.0 - (1.0 - t) ** 2
    return open_max * eased


def door_hold_open() -> float:
    return 78.0


def door_prompt(angle: float) -> str:
    if angle < 5:
        return "salon door CLOSED, vertical hinge on the LEFT of the leaf, one rigid door"
    if angle < 40:
        return (
            f"salon door opening ~{angle:.0f} degrees around LEFT vertical hinge, "
            "single rigid leaf, hinge edge fixed, no morph, no duplicate doors"
        )
    return (
        f"salon door OPEN ~{angle:.0f} degrees on LEFT hinge, character may pass, "
        "one rigid leaf only"
    )
