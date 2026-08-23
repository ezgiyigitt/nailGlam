"""CLI entry: python -m nail_glam_sprite_pipeline

Examples:
  python -m tool.nail_glam_sprite_pipeline --quality balanced
  python -m tool.nail_glam_sprite_pipeline --backend placeholder --pack
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Allow `python tool/nail_glam_sprite_pipeline/__main__.py`
_HERE = Path(__file__).resolve().parent
if str(_HERE.parent) not in sys.path:
    sys.path.insert(0, str(_HERE.parent))

from nail_glam_sprite_pipeline.config import PipelineConfig  # noqa: E402
from nail_glam_sprite_pipeline.pipeline import SpritePipeline  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NAIL GLAM continuous sprite pipeline")
    p.add_argument(
        "--quality",
        choices=("draft", "balanced", "cinematic"),
        default="balanced",
    )
    p.add_argument(
        "--backend",
        choices=("prompts", "placeholder"),
        default="prompts",
        help="prompts = AI job files; placeholder = CI stick figures",
    )
    p.add_argument("--pack", action="store_true", help="Pack placeholder sheet")
    p.add_argument("--out", type=Path, default=None)
    args = p.parse_args(argv)

    cfg = PipelineConfig(quality=args.quality)
    if args.out:
        cfg.output_dir = args.out

    summary = SpritePipeline(cfg).run(
        backend=args.backend,
        pack_placeholders=args.pack,
    )
    print(json.dumps(summary, indent=2))
    return 0 if summary.get("planValid") else 1


if __name__ == "__main__":
    raise SystemExit(main())
