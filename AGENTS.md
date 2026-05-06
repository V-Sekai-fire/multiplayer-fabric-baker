# AGENTS.md — multiplayer-fabric-baker

Headless Godot asset validator and exporter. Runs as an on-demand Fly Machine
(not a persistent web service). Deployed as `multiplayer-fabric-baker`.

## Fly.io deployment

The baker is a **job service** — one machine per bake job, started via the
Fly Machines API, exits when done.

### Pre-requisite: build the Godot binary image

The baker requires a pre-built Godot editor binary (double precision, from
`V-Sekai/world-godot`). Build and push it to GHCR before first baker deploy:

```bash
gh workflow run build-godot-binary.yml --repo V-Sekai-fire/multiplayer-fabric-baker
```

This takes ~1 hour. Result: `ghcr.io/v-sekai-fire/godot-editor-double:latest` (private).

### Triggering a bake job

```bash
flyctl machine run registry.fly.io/multiplayer-fabric-baker:latest \
  --app multiplayer-fabric-baker \
  --env ASSET_ID=<uuid> \
  --env URO_URL=https://hub.chibifire.com \
  -- avatar scenes/<uuid>.tscn out/<uuid>.scn
```

Exit codes: `0` = success, `1` = validation or upload failure.

### DNS

| URL | Notes |
|-----|-------|
| `https://bake.chibifire.com` | Posts results to Uro (same app, alias) |
| `https://bakeaf2f.chibifire.com` | Machine-specific alias (MAC suffix af2f) |

---

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
