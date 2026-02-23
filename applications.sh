#!/usr/bin/env bash
# arch-evo: Application install orchestrator
# Runs numbered scripts from apps/ sequentially
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.config"

SKIP_SCRIPTS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip)
            IFS=',' read -ra SKIP_SCRIPTS <<< "$2"
            shift 2
            ;;
        --from)
            FROM_SCRIPT="$2"
            shift 2
            ;;
        --only)
            ONLY_SCRIPT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: applications.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip 03,04    Skip specific scripts (comma-separated numbers)"
            echo "  --from 05       Start from script number"
            echo "  --only 08       Run only specific script"
            echo "  -h, --help      Show this help"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

section "arch-evo Application Installer"

# Ensure yay is available
ensure_yay

mkdir -p "${COMPLETED_DIR}"

# Collect scripts
mapfile -t scripts < <(find "${APPS_DIR}" -maxdepth 1 -name '*.sh' -type f | sort)

if [[ ${#scripts[@]} -eq 0 ]]; then
    warn "No scripts found in ${APPS_DIR}"
    exit 0
fi

# Filter and run
for script in "${scripts[@]}"; do
    script_name=$(basename "${script}")
    script_num="$((10#${script_name%%_*}))"

    # --only mode
    if [[ -n "${ONLY_SCRIPT:-}" ]] && [[ "${script_num}" != "${ONLY_SCRIPT}" ]]; then
        continue
    fi

    # --from mode
    if [[ -n "${FROM_SCRIPT:-}" ]] && [[ "${script_num}" -lt "${FROM_SCRIPT}" ]]; then
        log "Skipping ${script_name} (before --from ${FROM_SCRIPT})"
        continue
    fi

    # --skip mode
    skip=false
    for s in "${SKIP_SCRIPTS[@]}"; do
        if [[ "${script_num}" == "${s}" ]]; then
            skip=true
            break
        fi
    done
    if ${skip}; then
        log "Skipping ${script_name} (--skip)"
        continue
    fi

    # Already completed
    if is_completed "${script_name}"; then
        log "Already completed: ${script_name}"
        continue
    fi

    # Docker mode: skip hardware-dependent scripts
    if is_docker; then
        case "${script_num}" in
            06|13|16) # bluetooth, wifi, keyboard, docker (needs systemd)
                log "Docker mode: skipping ${script_name}"
                continue
                ;;
        esac
    fi

    section "Running: ${script_name}"

    while true; do
        if bash "${script}" 2>&1; then
            mark_completed "${script_name}"
            log "Completed: ${script_name}"
            break
        else
            error "Failed: ${script_name}"
            if is_docker; then
                warn "Continuing despite failure (Docker mode)..."
                break
            fi

            echo ""
            echo ">>> Press ENTER to continue <<<"
            read -r

            dialog_menu "Script Failed" "${script_name} failed. What do you want to do?" \
                "retry" "Retry this script" \
                "skip"  "Skip and continue" \
                "abort" "Abort installation"

            case "${_dialog_result}" in
                retry) log "Retrying ${script_name}..." ;;
                skip)  log "Skipping ${script_name}"; break ;;
                *)     die "Aborted by user" ;;
            esac
        fi
    done
done

section "All application scripts finished"
