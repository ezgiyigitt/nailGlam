"""Character identity lock — appearance only, never motion from old walks."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path

from PIL import Image
import numpy as np

from .config import AssetBundle


@dataclass
class CharacterIdentity:
    path: Path
    width: int
    height: int
    hair: str
    shirt: str
    pants: str
    shoes: str
    bag: str
    style: str
    prompt_lock: str
    mean_rgb: list[float]

    def to_dict(self) -> dict:
        d = asdict(self)
        d["path"] = str(self.path)
        return d


FORBIDDEN_STEMS = {
    "customer1_walk",
    "customer-walk-v1",
    "customer_01_walk",
    "walk",
}


def assert_not_motion_reference(path: Path) -> None:
    stem = path.stem.lower().replace(" ", "_")
    for bad in FORBIDDEN_STEMS:
        if bad in stem and "look" not in stem and "chair" not in stem:
            if "walk" in stem:
                raise ValueError(
                    f"Refusing motion reference from walking sheet: {path}. "
                    "Walking must be planned/generated from scratch."
                )


def load_identity(bundle: AssetBundle) -> CharacterIdentity:
    path = bundle.character_identity
    if not path.exists():
        raise FileNotFoundError(f"Character identity missing: {path}")
    assert_not_motion_reference(path)

    im = Image.open(path).convert("RGBA")
    arr = np.asarray(im)
    alpha = arr[:, :, 3] > 16
    if not alpha.any():
        raise ValueError("Identity image has no opaque pixels")
    rgb = arr[alpha][:, :3].astype(np.float64)
    mean = rgb.mean(axis=0).tolist()

    prompt_lock = (
        "EXACT same woman every frame — Character Identity Lock. "
        "Long voluminous wavy brown hair, large dark brown eyes, soft smile, "
        "gold hoop earrings, thin gold pendant necklace, "
        "mauve-pink button-down shirt with sleeves rolled to the elbows, "
        "high-waisted cream-white flared trousers, pink-and-white sneakers, "
        "small pink shoulder bag with gold chain. "
        "Premium stylized 3D cartoon mobile-game look. "
        "NEVER redesign face, hair, outfit, proportions, or age."
    )

    identity = CharacterIdentity(
        path=path,
        width=im.width,
        height=im.height,
        hair="long wavy brown",
        shirt="mauve-pink rolled-sleeve button shirt",
        pants="cream-white high-waisted flares",
        shoes="pink-white sneakers",
        bag="small pink shoulder bag",
        style="stylized 3D premium mobile cartoon",
        prompt_lock=prompt_lock,
        mean_rgb=mean,
    )
    return identity


def identity_delta(frame: Image.Image, identity: CharacterIdentity) -> float:
    """Cheap RGB histogram distance on opaque pixels (0 = identical)."""
    arr = np.asarray(frame.convert("RGBA"))
    alpha = arr[:, :, 3] > 16
    if not alpha.any():
        return 1.0
    mean = arr[alpha][:, :3].astype(np.float64).mean(axis=0)
    ref = np.array(identity.mean_rgb, dtype=np.float64)
    return float(np.linalg.norm(mean - ref) / (255.0 * np.sqrt(3)))


def save_identity_card(identity: CharacterIdentity, out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(identity.to_dict(), indent=2), encoding="utf-8")
