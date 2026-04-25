# syntax=docker/dockerfile:1
# Builds a Godot game project for export using the multiplayer-fabric-godot binary.
#
# Shares the same build infrastructure as Dockerfile.zone-fabric-build:
#   --build-context godot-src=/path/to/multiplayer-fabric-godot
#
# For local use, build via:
#   multiplayer-fabric-hosting/build-baker.sh
# For CI, the godot-src context is supplied by the workflow.

ARG FEDORA_IMAGE=fedora:41

# ── Build Godot editor (double precision, no mono) from source ────────────────
FROM ${FEDORA_IMAGE} AS godot-build

RUN dnf install -y \
    gcc gcc-c++ make \
    python3 python3-pip \
    pkgconfig \
    libX11-devel libXcursor-devel libXinerama-devel libXrandr-devel \
    libXi-devel mesa-libGL-devel mesa-libGLU-devel \
    alsa-lib-devel pulseaudio-libs-devel \
    ca-certificates && \
    dnf clean all && \
    pip3 install scons

WORKDIR /godot-src
COPY --from=godot-src . .

# Double precision editor — matches the export templates used for game projects.
RUN --mount=type=cache,target=/root/.cache/scons-godot \
    scons platform=linuxbsd target=editor \
        precision=double \
        accesskit=no \
        cache_path=/root/.cache/scons-godot \
        -j$(nproc)

# ── Baker runtime ─────────────────────────────────────────────────────────────
FROM ${FEDORA_IMAGE}

ARG INPUT_REPO
ARG INPUT_BRANCH
ARG INPUT_GAME_NAME
ARG INPUT_DEFAULT_EXPORT
ARG INPUT_XR_PLUGINS
ARG INPUT_NIGHTLY

ENV HOMEDIR=/root
ENV BIN=release/bin
ENV BUILD_ARGS=--headless
ENV BUILD_PLATFORMS="Linux Windows Mac Android Web"
ENV GODOT_EDITOR=godot.linuxbsd.editor.double.x86_64
ENV GODOT_REPO=V-Sekai-fire/multiplayer-fabric-godot
ENV TEMPLATE_DIR="${HOMEDIR}/.local/share/godot/export_templates"
ENV ANDROID_SDK_ROOT="${HOMEDIR}/android_sdk"
ENV ANDROID_HOME="${HOMEDIR}/android_sdk"
ENV XR_PLUGIN_REPO=GodotVR/godot_openxr_vendors

RUN dnf install -y \
    git curl jq zip unzip fontconfig \
    mesa-libGL mesa-libGLU alsa-lib pulseaudio-libs \
    libstdc++ libgcc ca-certificates \
    java-17-openjdk-headless && \
    dnf clean all

# Our Godot binary (double precision, built above)
COPY --from=godot-build \
    /godot-src/bin/godot.linuxbsd.editor.double.x86_64 \
    /usr/local/bin/godot.linuxbsd.editor.double.x86_64
RUN chmod +x /usr/local/bin/godot.linuxbsd.editor.double.x86_64 && \
    ln -s /usr/local/bin/godot.linuxbsd.editor.double.x86_64 /usr/local/bin/godot

WORKDIR ${HOMEDIR}

COPY ./build.sh /build.sh
RUN chmod +x /build.sh

COPY ./editor_settings-4.tres ./src/
COPY ./export_presets.cfg ./src/

# Download export templates matching our Godot version from our CI releases.
# The templates are produced by the linux-build CI job and stored as artifacts.
# In CI override GODOT_TEMPLATES_URL to point to the artifact download URL.
ENV GODOT_TEMPLATES_URL=""

ENTRYPOINT ["/bin/bash", "-c", "/build.sh"]
