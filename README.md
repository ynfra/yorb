# yorb

OrbStack Ubuntu VM provisioned via cloud-init with the full vibecoding toolchain.

## Installed tools

- **Docker CE** — container runtime
- **PHP 8.5** (ondrej/php) + Composer
- **Node.js 22 LTS** + npm
- **Deno** (system-wide)
- **Bun** (system-wide)
- **Claude Code** (`claude` CLI)
- **Codex** (`codex` CLI)
- **opencode** (`opencode` CLI + TUI)
- **agent-browser** (browser automation CLI)
- **htop, mc, git, ssh, curl, wget, jq** (system tools)

## Quick start

```bash
# Prerequisite: OrbStack installed (https://orbstack.dev)

git clone git@github.com:ynfra/yorb.git
cd yorb
./yorb.sh              # vibeenv, ai template, ubuntu:24.04

# Connect
orb shell vibeenv
```

Custom name / template / distro:

```bash
./yorb.sh mydev                    # ai template (default)
./yorb.sh mydev yai                # ai + yai repo cloned to /srv/yai
./yorb.sh mydev yai ubuntu:22.04   # older LTS
```

Or directly with the `orb` CLI:

```bash
orb create -c template/ai.yml ubuntu:24.04 vibeenv
```

## Files

| File | Purpose |
|------|---------|
| `template/ai.yml` | cloud-init — full toolchain |
| `template/yai.yml` | cloud-init — full toolchain + yai cloned to `/srv/yai` |
| `yorb.sh` | `orb create` wrapper with template selection |

See [AGENTS.md](AGENTS.md) for day-2 ops and editing guidance.
