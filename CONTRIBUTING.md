# Contributing

The V-Sekai open-source social VR game project — a Godot 4 project
that bundles multiplayer networking, VoIP, avatar loading (VRM),
and map support into a playable client.  This is the downstream Godot
project that consumes the engine fork from `multiplayer-fabric-godot`
and the addon library from `multiplayer-fabric-humanoid-project`.

## Guiding principles

- **Addons are pinned, not submodules.** Addon versions are locked by
  copying the relevant commit into `addons/`.  To update an addon,
  copy the new version over, run the project to verify it still loads,
  and commit as `Update <name> addon to <commit-sha>`.
- **Editor-first testing.** Changes must be validated by opening the
  project in the matching Godot editor build and running the affected
  scene.  Headless CI runs `godot --headless --quit` to catch import
  errors.
- **No orphaned autoloads.** Every autoload registered in
  `project.godot` must correspond to an existing `.gd` file.  Removing
  a script requires removing its autoload entry in the same commit.
- **Multiplayer state is server-authoritative.** Client-side prediction
  is permitted for visual smoothing only.  Gameplay state (positions,
  inventory, interactions) must always be confirmed by the server
  before being treated as canonical.
- **VoIP is opt-in.** Microphone capture must never be activated
  without explicit user action.  No autostart on scene load.

## Workflow

1. Clone the repo alongside the matching Godot editor fork.
2. Set `GODOT_EDITOR` to the path of the multiplayer-fabric Godot build.
3. Open the project:
   ```
   $GODOT_EDITOR --path .
   ```
4. Make changes, run affected scenes.
5. Commit with a sentence-case message describing what changed,
   e.g. `Add avatar spawn point to main lobby scene`.

## Design notes

### Editor / engine pairing

This project requires the multiplayer-fabric Godot fork, not upstream
Godot.  Check the `project.godot` `config/features` array for the
required engine version.  Running with a mismatched engine version
produces import errors or silent behavioural differences.

### XR mirror

`addons/V-Sekai.xr-mirror/` provides the XR compositor integration.
It exposes a `XRMirror` node that composites the XR camera feed into
a 2D viewport for spectator view.  The mirror node must be a direct
child of the XR origin — do not reparent it.

### Default assets

`vsk_default/` contains the default map, avatar, and UI assets shipped
with the project.  These are the fallback when a server does not
provide custom assets.  Do not commit large binary assets here;
reference them via the artifact system instead.
