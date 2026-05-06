# syntax=docker/dockerfile:1
# multiplayer-fabric-baker — headless Godot asset validator and exporter.
#
# Uses the pre-built Godot binary from GHCR so CI doesn't recompile Godot.
# Invoke via Fly Machines API (one machine per bake job):
#
#   flyctl machine run registry.fly.io/multiplayer-fabric-baker:latest \
#     --env ASSET_ID=<id> \
#     --env URO_URL=https://multiplayer-fabric-uro.fly.dev \
#     --env ASSET_TYPE=avatar \
#     --env SCENE_PATH=scenes/<id>.tscn \
#     -- godot --headless --path /app --script res://baker/run.gd \
#              -- avatar scenes/<id>.tscn out/<id>.scn

FROM ghcr.io/v-sekai-fire/godot-editor-double:latest AS godot

FROM almalinux:9

RUN dnf install -y \
        mesa-libGL alsa-lib pulseaudio-libs libstdc++ \
        fontconfig ca-certificates && \
    dnf clean all

# Copy pre-built Godot binary
COPY --from=godot /usr/local/bin/godot /usr/local/bin/godot

WORKDIR /app

# Copy the baker Godot project
COPY project.godot ./
COPY export_presets.cfg ./
COPY baker/ ./baker/
COPY addons/ ./addons/
COPY assets/ ./assets/
COPY vsk_default/ ./vsk_default/

# Pre-import assets headlessly so the first real run isn't slow
RUN godot --headless --path /app --import 2>&1 || true

ENV GODOT_BINARY=/usr/local/bin/godot

ENTRYPOINT ["godot", "--headless", "--path", "/app", "--script", "res://baker/run.gd", "--"]
