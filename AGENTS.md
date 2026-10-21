# yorb — Agent & Developer Guide

`yorb` provisions a ready-to-code OrbStack Ubuntu VM via cloud-init.
One command creates a VM with the full vibecoding toolchain pre-installed.

## Templates

| Template | File | Description |
|----------|------|-------------|
| `ai` | `template/ai.yml` | Full toolchain (default) — works on Ubuntu and Debian |
| `yai` | `template/yai.yml` | `ai` + clones `github.com/ynfra/yai` → `/srv/yai` |

Both templates auto-detect the distro from `/etc/os-release`: Ubuntu uses `ppa:ondrej/php`, Debian uses `packages.sury.org` (keyring from `debsuryorg-archive-keyring.deb`).

## What gets installed (all templates)

| Tool | How |
|------|-----|
| Docker CE | `get.docker.com` install script |
| PHP 8.5 + extensions | `ppa:ondrej/php` (Ubuntu) / `packages.sury.org` (Debian) |
| Composer | official installer → `/usr/local/bin/composer` |
| Node.js 22 LTS + npm | NodeSource |
| Deno | official installer → `/usr/local` |
| Bun | official installer → `/usr/local` |
| Claude Code | `npm install -g @anthropic-ai/claude-code` |
| Codex | `npm install -g @openai/codex` |
| opencode | `opencode.ai/install` → `/usr/local/bin/opencode` |
| agent-browser | `npm install -g agent-browser` |
| htop, mc, git, ssh, curl, wget, jq | apt packages |

## Create a VM

```bash
./yorb.sh [vm-name] [template] [distro]

./yorb.sh                          # vibeenv, ai, ubuntu:24.04
./yorb.sh mydev                    # mydev,   ai, ubuntu:24.04
./yorb.sh mydev yai                # mydev,   yai template
./yorb.sh mydev yai ubuntu:22.04   # mydev,   yai, ubuntu:22.04
./yorb.sh mydev ai debian:trixie   # mydev,   ai, debian 13

# Directly with orb CLI
orb create -c template/ai.yml ubuntu:24.04 vibeenv
```

## Provision an existing VM

Cloud-init only runs when a VM is created. `--apply` replays a template on a VM that
already exists: it installs the `packages:` list, then copies the `write_files:` setup
script to `/root/yorb-setup.sh` and runs it as root.

```bash
./yorb.sh --apply <vm-name> [template]
./yorb.sh --apply debian           # ai template on the existing `debian` VM
```

`--apply` extracts the script with awk and relies on the template layout: one
`write_files:` entry, the script body indented 6 spaces, and `runcmd:` right after it.

## Connect

```bash
orb shell vibeenv        # interactive shell
ssh vibeenv@orb          # SSH (OrbStack SSH shorthand)
orb run -m vibeenv <cmd> # run one command
```

## Day-2 operations

```bash
# Destroy and reprovision
orb delete vibeenv && ./yorb.sh

# Check cloud-init log inside the VM
orb run -m vibeenv cat /var/log/cloud-init-output.log
```

## Editing templates

All tool installs live in the `write_files:` setup script inside each template
(not in `runcmd:` directly — this ensures `HOME` and `PATH` are set correctly).
Add new tools to the script block; keep commands idempotent.

## Notes

- PHP 8.5 requires `ppa:ondrej/php` — not in the Ubuntu 24.04 main repo.
- `opencode` installs to `/root/.opencode`; the setup script symlinks the binary
  to `/usr/local/bin/opencode` and sets permissions so all users can execute it.
- Cloud-init runs at first boot only. Use `./yorb.sh --apply <vm>` for an existing VM, or delete and recreate it.
