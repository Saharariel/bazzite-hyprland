# Base image: Bazzite DX stable. `just build` passes the exact digest
# (see BASE_IMAGE in image-template.env) so every build is reproducible.
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-dx:stable

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

FROM ${BASE_IMAGE}

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
