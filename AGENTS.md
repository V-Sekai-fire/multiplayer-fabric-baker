# AGENTS.md — multiplayer-fabric-baker

Guidance for AI coding agents working in this submodule.

## What this is

Godot 4 project (headless, `editor=yes` Docker image) that validates and
exports user-supplied avatar / map scenes, chunks them with the casync
format, uploads chunks to the zone-backend chunk store, and posts the
resulting `.caibx` index to the `/storage/:id/bake` endpoint. It is the
asset baking step in cycle 6 of the upload pipeline.

## Running

```sh
# Invoked by Elixir baker escript — not run directly in development.
godot --headless --path <workspace> \
  --script res://baker/run.gd -- avatar|map scenes/<id>.tscn out/<id>.scn
```

Required environment variables: `ASSET_ID`, `URO_URL`.

Exit codes: 0 = success, 1 = validation or upload failure.

## Key files

| Path | Purpose |
|------|---------|
| `baker/run.gd` | Headless entrypoint: validate → export → chunk → upload → bake POST |
| `project.godot` | Godot 4.5 project config (app name: V-Sekai) |
| `docker/` | Docker context for the headless editor image |
| `scripts/check_spdx.py` | Pre-commit SPDX header checker |
| `addons/` | V-Sekai addons used during baking (VSKExporter, etc.) |

## Conventions

- This project runs headless only — do not add UI scenes.
- `baker/run.gd` must stay compatible with the zone-backend `/chunks` and
  `/storage/:id/bake` API contract.
- GDScript files need SPDX headers:
  ```gdscript
  # SPDX-License-Identifier: MIT
  # Copyright (c) 2026 K. S. Ernest (iFire) Lee
  ```
- Commit message style: sentence case, no `type(scope):` prefix.
  Example: `Handle empty caibx response from upload_asset_gd`
