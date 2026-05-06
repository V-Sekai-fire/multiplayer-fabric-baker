# AGENTS.md — multiplayer-fabric-baker

Headless Godot asset validator and exporter. Runs as an on-demand Fly Machine
(not a persistent web service). Deployed as `multiplayer-fabric-baker`.

## Fly.io deployment

The baker is a **job service** — one machine per bake job, started via the
Fly Machines API, exits when done.

### Pre-requisite: build the Godot editor binary

The baker requires a pre-built Godot editor binary (double precision) from
`V-Sekai-fire/multiplayer-fabric-build@b27142e94`. Build and push to GHCR
before deploying the baker:

```bash
gh workflow run build-godot-binary.yml --repo V-Sekai-fire/multiplayer-fabric-baker
```

Takes ~1 hour. Produces: `ghcr.io/v-sekai-fire/godot-editor-double:latest` (private).

**Note:** The deploy workflow uses `--local-only` (not `--remote-only`) so the
GitHub Actions runner can pull the private GHCR image. Fly's remote builder
has no GHCR credentials.

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
| `https://bake.chibifire.com` | Baker posts results to Uro here |
| `https://bakeaf2f.chibifire.com` | Machine-specific alias (MAC suffix `af2f`) |

## Godot binary builds (this repo)

Two binaries are built from `V-Sekai-fire/multiplayer-fabric-build@b27142e94`:

| Workflow | Binary | Flags | GHCR image | Used by |
|----------|--------|-------|------------|---------|
| `build-godot-binary.yml` | `godot.linuxbsd.editor.double.x86_64` | `target=editor precision=double` | `godot-editor-double:latest` | baker |
| `build-godot-zone-binary.yml` | `godot.linuxbsd.template_release.double.x86_64` | `target=template_release precision=double` | `godot-zone-double:latest` | zone server |

**Source layout:** SConstruct lives at `godot/SConstruct` inside the build repo
(not at root). Both Dockerfiles set `WORKDIR /build/godot` before running scons.

Trigger builds:
```bash
gh workflow run build-godot-binary.yml --repo V-Sekai-fire/multiplayer-fabric-baker
gh workflow run build-godot-zone-binary.yml --repo V-Sekai-fire/multiplayer-fabric-baker
```

## What this is

Godot 4 project (headless, editor mode) that validates and exports user-supplied
avatar / map scenes, chunks them with casync format, uploads chunks to the
zone-backend chunk store, and posts the resulting `.caibx` index to the
`/storage/:id/bake` endpoint. It is the asset baking step in cycle 6 of the
upload pipeline.

## Running locally

```sh
godot --headless --path <workspace> \
  --script res://baker/run.gd -- avatar|map scenes/<id>.tscn out/<id>.scn
```

Required environment variables: `ASSET_ID`, `URO_URL`.

## Key files

| Path | Purpose |
|------|---------|
| `baker/run.gd` | Headless entrypoint: validate → export → chunk → upload → POST bake |
| `project.godot` | Godot 4 project config |
| `docker/godot-binary/Dockerfile` | Builds editor binary image from multiplayer-fabric-build |
| `docker/godot-zone/Dockerfile` | Builds template_release binary image |
| `.github/workflows/build-godot-binary.yml` | Weekly editor binary → GHCR |
| `.github/workflows/build-godot-zone-binary.yml` | Weekly zone binary → GHCR |
| `.github/workflows/deploy.yml` | Deploys baker to Fly.io (local build) |

## Conventions

- Runs headless only — no UI scenes.
- `baker/run.gd` must stay compatible with the zone-backend `/chunks` and
  `/storage/:id/bake` API.
- GDScript files require SPDX headers:
  ```gdscript
  # SPDX-License-Identifier: MIT
  # Copyright (c) 2026 K. S. Ernest (iFire) Lee
  ```
- Commit style: sentence case, no `type(scope):` prefix.
