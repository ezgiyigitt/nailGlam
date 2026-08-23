# NAIL GLAM Sprite Pipeline

Reusable production pipeline for a **continuous** arrival animation:

`walk → door open → through door → walk to chair → slow down → turn → sit → seated`

## Hard rules

1. **Never** use old walking sprite sheets as motion / pose / img2img references.
2. Character appearance comes only from the **identity** asset (`character_look.png` by default).
3. Camera stays locked (no zoom/pan/rotate) for the whole sequence.
4. Output is **not** a looping walk cycle — one start-to-finish clip.

## Modules

| Module | Role |
|--------|------|
| `character_identity.py` | Identity lock + drift check |
| `scene_scale.py` | Auto proportions from character height = 1.0 |
| `walk_generator.py` | 8-phase gait model |
| `door_controller.py` | Rigid hinge door angles |
| `sit_controller.py` | Sit / turn phases |
| `motion_planner.py` | Full temporal `FrameState` timeline |
| `validators.py` | Continuity / camera / chronology |
| `frame_generator.py` | Prompt + strip jobs (AI backend) |
| `packer.py` | Equal-cell transparent sheet |
| `exporters.py` | JSON metadata + Flame atlas snippet |
| `pipeline.py` | Orchestrator |

## Run

From repo root:

```bash
python -m tool.nail_glam_sprite_pipeline --quality balanced
```

Draft / cinematic frame budgets:

```bash
python -m tool.nail_glam_sprite_pipeline --quality draft
python -m tool.nail_glam_sprite_pipeline --quality cinematic
```

CI placeholder sheet (no AI):

```bash
python -m tool.nail_glam_sprite_pipeline --backend placeholder --pack
```

## Outputs (`tool/nail_glam_sprite_pipeline/output/`)

- `character_identity.json`
- `scene_scale.json`
- `arrival_metadata.json` — fps, frames, timing, atlas coords
- `frame_prompts.json` — per-frame prompts
- `strip_generation_jobs.json` — 4-pose strip jobs for batch AI
- `prompts/frame_XXXX.txt` — individual generation packets
- `run_summary.json`

## Generating pixels

1. Run the pipeline (prompts backend).
2. For each job in `strip_generation_jobs.json`, call your image model with:
   - **reference:** only `assets/images/character_look.png`
   - **prompt:** job `"prompt"`
   - **forbidden:** any `*walk*` sprite sheet
3. Drop strip PNGs into `output/strips/`, split/pack with `packer.py` (or re-run a pack step).
4. QC checklist in the product brief must all pass before shipping.

## Swap assets later

Edit `PipelineConfig.assets`:

- `character_identity`
- `door`
- `chair`

Re-run — scale + motion recalculate automatically.
