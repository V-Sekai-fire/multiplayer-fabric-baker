# multiplayer-fabric-baker

Headless Godot asset validator and exporter. Runs as an on-demand Fly Machine; one machine per bake job, started via the Fly Machines API, exits when done.

## Fly.io deployment

### Pre-requisite: build the Godot editor binary

Build and push the editor binary to GHCR before deploying:

```bash
gh workflow run build-godot-binary.yml --repo V-Sekai-fire/multiplayer-fabric-baker
```

Takes ~1 hour. Produces `ghcr.io/v-sekai-fire/godot-editor-double:latest`.

The deploy workflow uses `--local-only` because Fly's remote builder cannot pull private GHCR images. The GitHub Actions runner authenticates to GHCR, pulls the image locally, and pushes the built app image to the Fly registry.

### Triggering a bake job

```bash
flyctl machine run registry.fly.io/multiplayer-fabric-baker:latest \
  --app multiplayer-fabric-baker \
  --env ASSET_ID=<uuid> \
  --env URO_URL=https://hub.chibifire.com \
  -- avatar scenes/<uuid>.tscn out/<uuid>.scn
```

Exit codes: `0` success, `1` validation or upload failure.

### DNS

| URL | Notes |
|-----|-------|
| `https://bake.chibifire.com` | Baker posts results to Uro |
| `https://bakeaf2f.chibifire.com` | Machine-specific alias (MAC suffix `af2f`) |

## Godot binary (this repo)

Built from `V-Sekai-fire/multiplayer-fabric-build@b27142e94`:

| Workflow | Binary | Flags | GHCR image |
|----------|--------|-------|------------|
| `build-godot-binary.yml` | `godot.linuxbsd.editor.double.x86_64` | `target=editor precision=double` | `godot-editor-double:latest` |

SConstruct lives at `godot/SConstruct` inside the build repo. The Dockerfile sets `WORKDIR /build/godot` before running scons.

The zone server binary (`godot-zone-double`) is built by `build-godot-zone-binary.yml` in `multiplayer-fabric-zone`.

```bash
gh workflow run build-godot-binary.yml --repo V-Sekai-fire/multiplayer-fabric-baker
```

## What this is

Godot 4 project running in headless editor mode. Validates and exports user-supplied avatar and map scenes, chunks them with casync, uploads chunks to the zone-backend chunk store, and posts the resulting `.caibx` index to `/storage/:id/bake`. This is cycle 6 of the upload pipeline.

## Running locally

```sh
godot --headless --path <workspace> \
  --script res://baker/run.gd -- avatar|map scenes/<id>.tscn out/<id>.scn
```

Required env vars: `ASSET_ID`, `URO_URL`.

## Key files

| Path | Purpose |
|------|---------|
| `baker/run.gd` | Entrypoint: validate → export → chunk → upload → POST bake |
| `project.godot` | Godot 4 project config |
| `docker/godot-binary/Dockerfile` | Builds editor binary image |
| `.github/workflows/build-godot-binary.yml` | Weekly editor binary → GHCR |
| `.github/workflows/deploy.yml` | Deploy to Fly.io |

## Conventions

- No UI scenes.
- `baker/run.gd` must stay compatible with zone-backend `/chunks` and `/storage/:id/bake`.
- GDScript files require SPDX headers:
  ```gdscript
  # SPDX-License-Identifier: MIT
  # Copyright (c) 2026 K. S. Ernest (iFire) Lee
  ```
- Commit style: sentence case, no `type(scope):` prefix.
