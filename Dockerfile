# syntax=docker/dockerfile:1
# Use a SteamCMD runtime image, NOT the existing backend-only Dockerfile.
ARG STEAMCMD_IMAGE=ghcr.io/ptero-eggs/steamcmd:debian
ARG PYTHON_IMAGE=python:3.13-slim-bookworm
FROM ${PYTHON_IMAGE} AS python-runtime
FROM ${STEAMCMD_IMAGE}

USER root
# Both stages must use Debian bookworm for binary compatibility.
# Fail instead of silently mixing Debian releases if upstream changes its tag.
RUN . /etc/os-release && test "$VERSION_CODENAME" = bookworm
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates libbz2-1.0 libcrypt1 libdb5.3 libexpat1 libffi8 \
       libgdbm6 libgdbm-compat4 liblzma5 libncursesw6 libreadline8 \
       libsqlite3-0 libssl3 libtinfo6 libuuid1 zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Directory copy merges with the base; existing SteamCMD/rcon files stay present.
COPY --from=python-runtime /usr/local/ /usr/local/
RUN ldconfig
COPY smoke.py /opt/wilds-runtime/smoke.py
ENV PATH="/usr/local/bin:${PATH}"

# Restore upstream runtime identity. Inherit ENTRYPOINT, CMD, WORKDIR and STOPSIGNAL.
USER container
RUN python3 /opt/wilds-runtime/smoke.py

# No game files, startup replacement, EOS values, credentials or LD_PRELOAD changes.
