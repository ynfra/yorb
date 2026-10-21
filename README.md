# ynfra / yorb

OrbStack Ubuntu/Debian VM provisioned via cloud-init with the full vibecoding
toolchain — Docker CE, PHP 8.5 + Composer, Node.js 22 LTS, Deno, Bun, Claude
Code, Codex, opencode, and agent-browser. One command, ready to code.

## Prerequisites

- macOS with [OrbStack](https://orbstack.dev) installed (`orb` CLI on PATH)
- Host git identity set (`git config --global user.name` / `user.email`) — it is copied into the VM; missing identity only warns

## Usage

```bash
./yorb.sh                          # create VM "vibeenv" (ai template, ubuntu:24.04)
orb shell vibeenv                  # interactive shell (or: ssh vibeenv@orb)

# custom name / template / distro
./yorb.sh mydev yai ubuntu:22.04
./yorb.sh mydev ai debian:trixie   # Debian 13

# provision an existing VM (cloud-init only runs at create)
./yorb.sh --apply debian
```

## Templates

| Template | File | Description |
|---|---|---|
| `ai` (default) | `template/ai.yml` | Full toolchain (list above) plus htop, mc, git, ssh, curl, wget, jq |
| `yai` | `template/yai.yml` | `ai` + clones `github.com/ynfra/yai` to `/srv/yai` |

`yorb.sh` renders the chosen template with your git identity (`envsubst`) and
runs `orb create`. Direct equivalent without identity injection:
`orb create -c template/ai.yml ubuntu:24.04 vibeenv`.

## Notes

- Cloud-init runs at first boot only — reprovision with `orb delete vibeenv && ./yorb.sh`, or replay a template on an existing VM with `./yorb.sh --apply <vm> [template]`.
- Templates auto-detect the distro: Ubuntu uses `ppa:ondrej/php`, Debian uses `packages.sury.org` via `debsuryorg-archive-keyring` (PHP 8.5 is in neither distro's main repo).
- Check provisioning output: `orb run -m vibeenv cat /var/log/cloud-init-output.log`.

See [AGENTS.md](AGENTS.md) for the per-tool install details, template editing rules, and day-2 operations.
