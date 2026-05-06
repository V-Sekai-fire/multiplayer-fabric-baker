# syntax=docker/dockerfile:1
# Builds the Godot zone server runtime binary (double precision, template_release, no Mono).
# Lighter than the editor binary — no import/export tools, just the game runtime.
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
    scons platform=linuxbsd target=template_release \
        precision=double \
        accesskit=no \
        linuxbsd_speechd=no \
        cache_path=/root/.cache/scons-godot \
        -j"$(nproc)" \
    && strip bin/godot.linuxbsd.template_release.double.x86_64

# ── Minimal runtime image ─────────────────────────────────────────────────────
FROM almalinux:9

RUN dnf install -y \
        mesa-libGL alsa-lib pulseaudio-libs libstdc++ \
        fontconfig ca-certificates && \
    dnf clean all

COPY --from=build \
    /godot-src/bin/godot.linuxbsd.template_release.double.x86_64 \
    /usr/local/bin/godot

RUN chmod +x /usr/local/bin/godot

RUN godot --version
