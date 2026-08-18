# Project Log

Narrative record of decisions, problems, and learnings for the docker-desk project.

---

## 2026-08-18 — desk-doctor, playwright, s6 auto-heal

**Context**: Previous session (ATC Lab project) uncovered that the Dockerfile's `RUN pi install` commands were silently failing — not because the commands errored, but because they installed into `/root/.pi` (build runs as root) while the runtime user `abc` looks in `/config/.pi`. Compounded by the bind mount `./home_volume:/config` completely shadowing the image's `/config`.

**Mystery solved**: Two independent failures:
1. Build runs as root → pi installs to `/root/.pi`, invisible to runtime user
2. Bind mount shadows image's `/config` → even if we fixed #1, a fresh volume would be empty

**What we built**:

- **desk-doctor** — 13-check idempotent self-heal script. Runs at startup via s6-overlay one-shot task. Checks required binaries, pi packages, playwright, seeds fresh home_volumes from an image-baked `/config` snapshot. Only ever adds missing things; never deletes or overwrites.

- **Playwright 1.61.0** — Global install with `--no-user` (critical: pip defaults to user site under `~/.local` which lands under `/config` and gets shadowed). Chromium browsers baked into the image (~280MB).

- **Seed snapshot** — `cp -a /config/. /usr/share/docker-desk/seed-config/` at build time. Copies VS Code settings, desktop shortcuts, etc. to a path not shadowed by the bind mount. desk-doctor uses this to populate a fresh `home_volume`.

- **s6 one-shot task** — Auto-runs desk-doctor at container startup as user `abc` with `HOME=/config`. No entrypoint surgery needed — just a directory under `root_data/etc/s6-overlay/s6-rc.d/user/contents.late/desk-doctor/` with `type=oneshot` and a `run` script.

**Key Docker concepts learned**:

- Build layers vs runtime mounts: what's baked into the image is not what the container sees if bind-mounted over
- Daemon (not kernel) creates missing bind sources as empty `root:root` directories
- Named volumes seed from image on first use; bind mounts don't — they completely replace
- s6-overlay lets you add one-shot tasks without touching `/init`

**Workflow decision**: desk-doctor lives at `docker-desk-doctor/` (build context root, not under `projects/`). Bind-mounted into the container so in-container edits persist and are picked up live. Symlink at `/usr/local/bin/desk-doctor` for convenience.

**Bugs caught**:
- `pi list` output has no trailing space on package lines — the "installed" grep missed and re-ran installs (harmless but noisy, fixed)
- Seed snapshot `cp -a` failed because parent directory didn't exist — needed `mkdir -p` first
