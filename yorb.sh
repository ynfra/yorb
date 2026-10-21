#!/usr/bin/env bash
# yorb/yorb.sh — create an OrbStack VM from a template/ai.yml or template/yai.yml.
#
# Usage:
#   ./yorb.sh [vm-name] [template] [distro]
#   ./yorb.sh --apply <vm-name> [template]   provision an existing VM (cloud-init only runs at create)
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
#   ./yorb.sh mydev ai debian:trixie   # mydev,    ai template, debian 13
#   ./yorb.sh --apply debian           # run the ai setup inside the existing 'debian' VM
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"
    exit 0
fi

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then
    APPLY=1
    shift
    [[ -n "${1:-}" ]] || { echo "ERROR: --apply needs a vm-name" >&2; exit 1; }
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

if [[ "${APPLY}" == "1" ]]; then
    # Replay the template on an existing VM: install `packages:`, then run the
    # write_files setup script as root. Relies on the template layout (one
    # write_files entry, script body indented 6 spaces, ends at `runcmd:`).
    PACKAGES="$(awk '/^packages:/{f=1;next} f&&/^  - /{print $2;next} f&&/^[^ ]/{exit}' "${RENDERED}" | tr '\n' ' ')"

    echo "=== yorb: applying template to existing OrbStack VM ==="
    echo "  name     : ${VM_NAME}"
    echo "  template : ${TEMPLATE}  (${CLOUD_INIT})"
    echo "  git      : ${GIT_NAME} <${GIT_EMAIL}>"
    echo ""

    orb run -m "${VM_NAME}" sudo env DEBIAN_FRONTEND=noninteractive bash -c "apt-get update -q && apt-get upgrade -y && apt-get install -y ${PACKAGES}"
    awk '/^    content: \|/{f=1;next} f&&/^[^ ]/{exit} f{sub(/^      /,""); print}' "${RENDERED}" \
        | orb run -m "${VM_NAME}" sudo bash -c 'cat > /root/yorb-setup.sh && chmod 700 /root/yorb-setup.sh'
    orb run -m "${VM_NAME}" sudo /root/yorb-setup.sh

    echo ""
    echo "=== done — connect with ==="
    echo "  orb shell ${VM_NAME}"
    echo "  ssh ${VM_NAME}@orb"
    exit 0
fi

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
