#!/usr/bin/env bash
# yorb/yorb.sh — create an OrbStack VM from a template/ai.yml or template/yai.yml.
#
# Usage:
#   ./yorb.sh [vm-name] [template] [distro]
#
# Defaults:
#   vm-name   vibeenv
#   template  ai          (resolves to template/ai.yml)
#   distro    ubuntu:24.04
#
# Available templates:
#   ai    full toolchain (docker, php8.5, node, deno, bun, claude, codex, opencode, agent-browser)
#   yai   ai + clones github.com/ynfra/yai into /srv/yai
#
# Examples:
#   ./yorb.sh                          # vibeenv,  ai template, ubuntu:24.04
#   ./yorb.sh mydev                    # mydev,    ai template, ubuntu:24.04
#   ./yorb.sh mydev yai                # mydev,    yai template
#   ./yorb.sh mydev yai ubuntu:22.04   # mydev,    yai template, ubuntu:22.04
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
fi

VM_NAME="${1:-vibeenv}"
TEMPLATE="${2:-ai}"
DISTRO="${3:-ubuntu:24.04}"
CLOUD_INIT="${SCRIPT_DIR}/template/${TEMPLATE}.yml"

command -v orb >/dev/null 2>&1 || {
    echo "ERROR: orb CLI not found — install OrbStack from https://orbstack.dev" >&2
    exit 1
}

[[ -f "${CLOUD_INIT}" ]] || {
    echo "ERROR: template not found: ${CLOUD_INIT}" >&2
    echo "Available: $(ls "${SCRIPT_DIR}/template/"*.yml | xargs -n1 basename | sed 's/\.yml//' | tr '\n' ' ')" >&2
    exit 1
}

# Read git identity from host and render template via envsubst
export GIT_NAME="$(git config --global user.name 2>/dev/null || echo '')"
export GIT_EMAIL="$(git config --global user.email 2>/dev/null || echo '')"

if [[ -z "${GIT_NAME}" || -z "${GIT_EMAIL}" ]]; then
    echo "WARN: host git identity incomplete — git config will stay unset in the VM." >&2
    echo "      Fix with: git config --global user.name '...' && git config --global user.email '...'" >&2
fi

RENDERED="${SCRIPT_DIR}/template/.${TEMPLATE}.rendered.yml"
trap 'rm -f "${RENDERED}"' EXIT

envsubst '${GIT_NAME} ${GIT_EMAIL}' < "${CLOUD_INIT}" > "${RENDERED}"

echo "=== yorb: creating OrbStack VM ==="
echo "  name     : ${VM_NAME}"
echo "  template : ${TEMPLATE}  (${CLOUD_INIT})"
echo "  distro   : ${DISTRO}"
echo "  git      : ${GIT_NAME} <${GIT_EMAIL}>"
echo ""

orb create -c "${RENDERED}" "${DISTRO}" "${VM_NAME}"

echo ""
echo "=== done — connect with ==="
echo "  orb shell ${VM_NAME}"
echo "  ssh ${VM_NAME}@orb"
