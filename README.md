# hermes-shipyard

Custom Hermes Agent image based on `nousresearch/hermes-agent` with extra CLI tools baked in:

- `age`, `sops` — secrets encryption/decryption
- `himalaya` — email CLI
- `git`, `jq`, `ripgrep`, `curl`, `gnupg`
- `sudo`, with passwordless sudo for the `hermes` user

Installing the tools in the image (instead of inside a running container) means they survive container recreation and upstream upgrades. Hermes data stays on the host through the `/opt/data` bind mount. The upstream entrypoint is unchanged, so `HERMES_UID`/`HERMES_GID`, Docker socket group setup, and the privilege drop to `hermes` all behave as they do upstream.

`sops` and `himalaya` are downloaded from their GitHub releases and verified against pinned SHA256 checksums.

## Build Locally

```sh
docker build -t hermes-shipyard:latest .
```

To pin the upstream Hermes image:

```sh
docker build \
  --build-arg HERMES_BASE_IMAGE=nousresearch/hermes-agent:latest \
  -t hermes-shipyard:latest .
```

To change the tool versions, update `SOPS_VERSION` / `HIMALAYA_VERSION` together with their checksums in the `Dockerfile`.

## Use With Compose

Point your Hermes service at this image instead of building locally:

```yaml
services:
  hermes:
    image: ghcr.io/vkhurana/hermes-shipyard:latest
    command: gateway run
    volumes:
      - ./hermes/data:/opt/data
```

To update:

```sh
docker compose pull hermes && docker compose up -d --no-deps hermes
```

## Publish To GHCR

After pushing this repo to GitHub, the included workflow publishes daily, on each push to `main`, and on manual dispatch:

- `ghcr.io/<owner>/<repo>:latest` from the default branch
- `ghcr.io/<owner>/<repo>:<git-sha>` for each build

Each build pulls the latest `nousresearch/hermes-agent:latest`, so the daily run picks up upstream releases.
