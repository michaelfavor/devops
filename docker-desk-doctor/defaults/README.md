# Image defaults for desk-doctor

These files are baked into the image at `/usr/local/share/docker-desk/defaults/`
and used by `desk-doctor` to restore pi agent state **only when a file is
missing** — existing files are never overwritten.

- `settings.json` — minimal, provider-neutral pi settings. After a restore,
  the user must reconfigure their own provider/model (the doctor cannot
  know those).
- `models.json` is intentionally NOT included here: pi regenerates it via
  `pi update --models`, which needs network access.

To add more seed files (e.g., a stock config for another tool), drop the
file in this directory and add its name to the restore loop in
`desk-doctor.sh`.
