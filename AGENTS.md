# AGENTS.md — Working Guide

Guidance for AI agents and humans working on `docker-sshd`. Read this before touching CI, tags, or the Dockerfile.

## What this is

A slim, highly configurable OpenSSH server image on Alpine Linux (`bash` and `rsync` included). One codebase, published to three registries:

| Registry | Image |
| --- | --- |
| Docker Hub (primary, >5M pulls) | `hermsi/alpine-sshd` |
| Quay | `quay.io/hermsi1337/alpine-sshd` |
| GHCR | `ghcr.io/hermsi1337/docker-sshd` |

### Tag schema — public contract, do not change

Every build publishes exactly these tags (identical set on all three registries):

- `latest`
- `<ssh-version>` — e.g. `10.3_p1-r0`
- `<ssh-version>-alpine` — e.g. `10.3_p1-r0-alpine`
- `<ssh-version>-alpine<alpine-version>` — e.g. `10.3_p1-r0-alpine3.24`

`<ssh-version>` is the full Alpine package version of `openssh` (including the `_pN-rN` suffix); `<alpine-version>` is the two-part Alpine branch (`3.24`, not `3.24.1`). Downstream users pin these tags — never rename, drop, or reformat them.

## Repository layout

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Alpine base + `openssh=<exact version>`. The two **fallback ARGs** at the top (`ALPINE_VERSION`, `OPENSSH_VERSION`) only apply when building without `--build-arg`; CI always overrides them. |
| `entrypoint.sh` | Runtime configuration: root login modes (locked / password / keypair), `SSH_USERS` creation, host key generation, then `exec sshd -D -e`. |
| `conf.d/etc/profile.d/ubuntu-bashrc.sh` | Ubuntu-style default `.bashrc` baked into the image. |
| `.github/workflows/build-and-deploy.yaml` | The only workflow: lint job + multi-arch build/push job. |
| `.github/dependabot.yml` | Weekly version bumps for GitHub Actions. |
| `.gitattributes` | Enforces LF line endings (`* text=auto eol=lf`). Keep it that way. |

## CI/CD (`build-and-deploy.yaml`)

- **Triggers:**
  - `schedule` — Mondays 02:00 UTC. This is a **security rebuild**: it always builds with `--no-cache`/`pull` and pushes, even when detected versions are unchanged, so upstream Alpine/OpenSSH fixes reach the published tags.
  - `push` to `master` — full build and push.
  - `workflow_dispatch` — manual full build and push.
  - `pull_request` — build-only validation: both platforms are built, but there are no registry logins and `push: false`, so PRs (including forks) need no secrets.
- **Version detection at build time** (step id `versions`): the Alpine version comes from `docker run --rm alpine:latest` reading `/etc/os-release`; the exact `openssh` package version comes from `apk policy openssh` inside that same image. No HTML scraping. This runtime detection is the **source of truth** for what gets built and tagged.
- **Lint job:** `bash -n` on every `*.sh` file; the build job depends on it.
- **Multi-arch:** `linux/amd64,linux/arm64` via `setup-qemu-action` + `setup-buildx-action` + `build-push-action`; tags/labels come from `metadata-action` (which also lowercases the GHCR owner).
- **Concurrency:** one group per ref. Superseded PR runs are cancelled; `master`/schedule/dispatch runs are never cancelled mid-push.
- **Secrets** (Actions secrets, required for pushing): `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `QUAY_USERNAME`, `QUAY_TOKEN`. GHCR authenticates with the built-in `GITHUB_TOKEN` (`permissions: packages: write`), no extra secret.

## Invariants — do not break

1. **The tag schema is frozen** (see above).
2. **The schedule always builds and pushes.** Do not add "skip if version unchanged" logic — weekly no-cache rebuilds shipping security fixes under unchanged tags are the whole point.
3. **Runtime detection wins.** The Dockerfile fallback ARGs exist only for manual `docker build` convenience. Bump them periodically so they stay honest, but never make CI depend on them.
4. All three registries receive the identical tag set from a single build.

## Common tasks

### Bump the Dockerfile fallback ARGs

Verify the real values, then update only the two `ARG` lines at the top of `Dockerfile`:

```bash
docker run --rm alpine:latest sh -c '. /etc/os-release && echo $VERSION_ID'            # ALPINE_VERSION (use two-part form)
docker run --rm alpine:latest sh -c 'apk update -q >/dev/null && apk policy openssh'   # OPENSSH_VERSION (exact, e.g. 10.3_p1-r0)
```

Cross-check on <https://pkgs.alpinelinux.org/packages?name=openssh> — `x86_64` and `aarch64` must carry the same version, otherwise the pinned multi-arch build fails.

### Re-enable the workflow if GitHub disabled it

GitHub disables scheduled workflows after ~60 days without repository activity (`disabled_inactivity`). **This has already happened once** in this repo. Check and fix:

```bash
gh workflow list --all      # look for "disabled_inactivity"
gh workflow enable build-and-deploy.yaml
```

Any push to `master` also re-activates the schedule.

### New OpenSSH / Alpine releases

Nothing to do. The weekly build picks up a new `openssh` package automatically as soon as the current Alpine stable branch ships it (example: upstream OpenSSH 10.4 was released 2026-07-08 but not yet packaged in Alpine v3.24 as of 2026-07-18 — it will flow in by itself). A new Alpine major (`3.25`, …) arrives the same way via `alpine:latest`.

## Note for agents: CLAUDE.md is a symlink

`CLAUDE.md` is committed as a **git symlink** (mode `120000`) pointing to `AGENTS.md`. On Windows checkouts without symlink support (`core.symlinks=false`) it materializes as a plain text file whose content is the string `AGENTS.md` — that is expected and fine. **Never re-stage it with `git add CLAUDE.md`** from such a working tree; that would silently replace the symlink with a regular file. Verify integrity with `git ls-files -s CLAUDE.md` — the mode must stay `120000`.
