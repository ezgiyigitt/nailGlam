"""Pack AI-generated strip PNGs into the continuous arrival sheet.

Usage:
  1. Generate strip images from strip_generation_jobs.json
     (identity ref ONLY: character_look.png — never old walk sheets)
  2. Save as output/strips/strip_000.png, strip_001.png, ...
  3. python tool/nail_glam_sprite_pipeline/pack_strips.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

_HERE = Path(__file__).resolve().parent
if str(_HERE.parent) not in sys.path:
    sys.path.insert(0, str(_HERE.parent))

from nail_glam_sprite_pipeline.packer import key_black, pack_sheet, save_individual_frames
from nail_glam_sprite_pipeline.exporters import export_metadata, write_flame_atlas_snippet
from nail_glam_sprite_pipeline.config import PipelineConfig
from nail_glam_sprite_pipeline.motion_planner import plan_motion
from nail_glam_sprite_pipeline.scene_scale import solve_scale
from nail_glam_sprite_pipeline.character_identity import load_identity


def row_figures(im: Image.Image, count: int) -> list[Image.Image]:
    arr = np.asarray(key_black(im))
    vis = arr[:, :, 3] > 16
    occ = vis.any(axis=0)
    runs: list[tuple[int, int]] = []
    start = None
    for i, filled in enumerate(occ):
        if filled and start is None:
            start = i
        elif not filled and start is not None:
            if i - start > 8:
                runs.append((start, i))
            start = None
    if start is not None and im.width - start > 8:
        runs.append((start, im.width))
    runs.sort(key=lambda r: r[1] - r[0], reverse=True)
    picked = sorted(runs[:count], key=lambda r: r[0])
    frames = []
    for x0, x1 in picked:
        frames.append(Image.fromarray(arr[:, x0:x1], "RGBA"))
    return frames


def main() -> int:
    cfg = PipelineConfig()
    out = cfg.output_dir
    strips_dir = out / "strips"
    jobs = json.loads((out / "strip_generation_jobs.json").read_text(encoding="utf-8"))
    identity = load_identity(cfg.assets)
    scale = solve_scale(
        cfg.scale_hints,
        identity_path=cfg.assets.character_identity,
        door_path=cfg.assets.door,
        chair_path=cfg.assets.chair,
    )
    plan = plan_motion(cfg, scale)

    all_frames: list[Image.Image] = []
    for i, job in enumerate(jobs):
        path = strips_dir / f"strip_{i:03d}.png"
        if not path.exists():
            print(f"missing {path} — stop after {len(all_frames)} frames")
            break
        expected = job["end_frame"] - job["start_frame"] + 1
        figs = row_figures(Image.open(path), expected)
        if len(figs) < expected:
            print(f"{path}: found {len(figs)} figures, want {expected}")
        all_frames.extend(figs)

    if not all_frames:
        print("No strips found in", strips_dir)
        return 1

    save_individual_frames(all_frames, out / "frames")
    sheet, atlas = pack_sheet(
        all_frames,
        cell_w=cfg.cell_width,
        cell_h=cfg.cell_height,
        padding=cfg.sheet_padding,
        columns=8,
    )
    for i, e in enumerate(atlas):
        if i < plan.frame_count:
            e.sequence = plan.frames[i].sequence
    sheet_path = out / "arrival_continuous_sheet.png"
    sheet.save(sheet_path)
    # Trim plan to available frames for metadata
    plan.frames = plan.frames[: len(all_frames)]
    export_metadata(
        plan,
        atlas,
        out / "arrival_metadata.json",
        sheet_name=sheet_path.name,
        scale_notes=scale.notes,
        validation_issues=[],
    )
    (out / "flame_atlas_snippet.dart.txt").write_text(
        write_flame_atlas_snippet(atlas, cfg.cell_width, cfg.cell_height),
        encoding="utf-8",
    )
    print(f"packed {len(all_frames)} frames -> {sheet_path} ({sheet.size})")
    print("identity used:", identity.path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
