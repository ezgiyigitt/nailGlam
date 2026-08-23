"""Orchestrates the full NAIL GLAM continuous sprite pipeline."""

from __future__ import annotations

import json
from pathlib import Path

from .character_identity import load_identity, save_identity_card
from .config import PipelineConfig
from .exporters import export_metadata, export_prompts, write_flame_atlas_snippet
from .frame_generator import (
    FrameBackend,
    PlaceholderBackend,
    PromptOnlyBackend,
    build_strip_jobs,
    prompts_for_plan,
    write_generation_jobs,
)
from .motion_planner import plan_motion
from .packer import pack_sheet, save_individual_frames
from .scene_scale import solve_scale
from .validators import validate_plan


class SpritePipeline:
    def __init__(self, config: PipelineConfig | None = None) -> None:
        self.config = config or PipelineConfig()

    def run(
        self,
        *,
        backend: str = "prompts",
        pack_placeholders: bool = False,
    ) -> dict:
        cfg = self.config
        out = cfg.output_dir
        out.mkdir(parents=True, exist_ok=True)

        identity = load_identity(cfg.assets)
        save_identity_card(identity, out / "character_identity.json")

        scale = solve_scale(
            cfg.scale_hints,
            identity_path=cfg.assets.character_identity,
            door_path=cfg.assets.door,
            chair_path=cfg.assets.chair,
        )
        (out / "scene_scale.json").write_text(
            json.dumps(scale.to_dict(), indent=2), encoding="utf-8"
        )

        plan = plan_motion(cfg, scale)
        report = validate_plan(plan, cfg)
        (out / "validation_plan.json").write_text(
            json.dumps({"ok": report.ok, "issues": report.issues}, indent=2),
            encoding="utf-8",
        )

        export_prompts(plan, out / "frame_prompts.json", identity.prompt_lock)
        jobs = build_strip_jobs(plan, identity, per_strip=4)
        write_generation_jobs(jobs, out / "strip_generation_jobs.json")

        # Per-frame prompt files for manual / API generation
        prompt_dir = out / "prompts"
        prompt_dir.mkdir(exist_ok=True)
        backend_impl: FrameBackend
        if backend == "placeholder":
            backend_impl = PlaceholderBackend()
        else:
            backend_impl = PromptOnlyBackend()

        generated = []
        for fr, prompt in prompts_for_plan(plan, identity):
            path = backend_impl.generate(
                prompt,
                prompt_dir / f"frame_{fr.frame_number:04d}.png",
                identity.path,
            )
            generated.append(str(path))

        sheet_path = None
        atlas_snippet = None
        if pack_placeholders and backend == "placeholder":
            from PIL import Image

            images = [
                Image.open(prompt_dir / f"frame_{i:04d}.png")
                for i in range(plan.frame_count)
            ]
            save_individual_frames(images, out / "frames")
            sheet, atlas = pack_sheet(
                images,
                cell_w=cfg.cell_width,
                cell_h=cfg.cell_height,
                padding=cfg.sheet_padding,
                columns=8,
            )
            for i, e in enumerate(atlas):
                e.sequence = plan.frames[i].sequence
            sheet_path = out / "arrival_continuous_sheet.png"
            sheet.save(sheet_path)
            export_metadata(
                plan,
                atlas,
                out / "arrival_metadata.json",
                sheet_name=sheet_path.name,
                scale_notes=scale.notes,
                validation_issues=report.issues,
            )
            atlas_snippet = write_flame_atlas_snippet(
                atlas, cfg.cell_width, cfg.cell_height
            )
            (out / "flame_atlas_snippet.dart.txt").write_text(
                atlas_snippet, encoding="utf-8"
            )
        else:
            # Metadata without raster atlas coords yet
            export_metadata(
                plan,
                [],
                out / "arrival_metadata.json",
                sheet_name="pending_generation",
                scale_notes=scale.notes,
                validation_issues=report.issues,
            )

        summary = {
            "frameCount": plan.frame_count,
            "fps": plan.fps,
            "sequence": plan.sequence,
            "planValid": report.ok,
            "issues": report.issues,
            "scaleNotes": scale.notes,
            "stripJobs": len(jobs),
            "outputDir": str(out),
            "sheet": str(sheet_path) if sheet_path else None,
            "identity": str(identity.path),
            "policy": "no_old_walk_sprites_as_motion_reference",
        }
        (out / "run_summary.json").write_text(
            json.dumps(summary, indent=2), encoding="utf-8"
        )
        return summary
