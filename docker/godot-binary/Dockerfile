# syntax=docker/dockerfile:1
# Builds the V-Sekai Godot editor binary (double precision, headless-capable).
# The resulting image is used as a base for multiplayer-fabric-baker so that
# CI never recompiles Godot from source on every baker build.
#
# Build contexts:
#   godot-src — checkout of V-Sekai/world-godot

FROM almalinux:9 AS build

RUN dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf install -y \
        gcc gcc-c++ make \
        python3 python3-pip \
        pkgconf-pkg-config \
        libX11-devel libXcursor-devel libXinerama-devel libXrandr-devel \
        libXi-devel mesa-libGL-devel \
        alsa-lib-devel pulseaudio-libs-devel \
        ca-certificates && \
    dnf clean all && \
    pip3 install scons

WORKDIR /godot-src
COPY --from=godot-src . .

RUN --mount=type=cache,target=/root/.cache/scons-godot \
    scons platform=linuxbsd target=editor \
        precision=double \
        accesskit=no \
        linuxbsd_speechd=no \
        cache_path=/root/.cache/scons-godot \
        -j"$(nproc)" \
    && strip bin/godot.linuxbsd.editor.double.x86_64

# ── Minimal runtime image (just the binary) ──────────────────────────────────
FROM almalinux:9

RUN dnf install -y \
        mesa-libGL alsa-lib pulseaudio-libs libstdc++ \
        fontconfig ca-certificates && \
    dnf clean all

COPY --from=build \
    /godot-src/bin/godot.linuxbsd.editor.double.x86_64 \
    /usr/local/bin/godot

RUN chmod +x /usr/local/bin/godot

# Smoke test
RUN godot --version
