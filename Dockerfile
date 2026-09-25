# syntax=docker/dockerfile:1.7

ARG HERMES_BASE_IMAGE=nousresearch/hermes-agent:latest
FROM ${HERMES_BASE_IMAGE}

ARG SOPS_VERSION=3.13.3
ARG HIMALAYA_VERSION=2.0.0
ARG TARGETARCH

# Tools are baked into the image so they survive container recreation/upgrades.
# Hermes data and keys stay on the host via the /opt/data bind mount.
USER root
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        age \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        ripgrep \
        sudo; \
    case "${TARGETARCH:-amd64}" in \
        amd64) \
            SOPS_ARCH="amd64"; \
            SOPS_SHA256="e5bec3346a873ae91d871550f3e698c1aad962aff462a080e40f25fde17fef6b"; \
            HIMALAYA_TARGET="x86_64-linux"; \
            HIMALAYA_SHA256="2c4184b43787b789de121e17b255d479b8cb03fc91b49fecc5197a2b7772bcf3"; \
            ;; \
        arm64) \
            SOPS_ARCH="arm64"; \
            SOPS_SHA256="53b0abacd38ef1b12a66d6c100956691b9cefce018d91f81e73ddf7438b94d77"; \
            HIMALAYA_TARGET="aarch64-linux"; \
            HIMALAYA_SHA256="c395e87cef819fb16249adeb631c216424d61fdd99365842517585ef8f9c2a70"; \
            ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${SOPS_ARCH}" \
        -o /usr/local/bin/sops; \
    echo "${SOPS_SHA256}  /usr/local/bin/sops" | sha256sum -c -; \
    chmod 0755 /usr/local/bin/sops; \
    curl -fsSL \
        "https://github.com/pimalaya/himalaya/releases/download/v${HIMALAYA_VERSION}/himalaya.${HIMALAYA_TARGET}.tgz" \
        -o /tmp/himalaya.tgz; \
    echo "${HIMALAYA_SHA256}  /tmp/himalaya.tgz" | sha256sum -c -; \
    tar -xzf /tmp/himalaya.tgz -C /tmp; \
    install -m 0755 /tmp/himalaya /usr/local/bin/himalaya; \
    install -d -m 0755 /etc/sudoers.d; \
    echo 'hermes ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hermes; \
    chmod 0440 /etc/sudoers.d/hermes; \
    visudo -cf /etc/sudoers.d/hermes; \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Upstream runs as root and its entrypoint drops to the hermes user.
WORKDIR /opt/hermes
