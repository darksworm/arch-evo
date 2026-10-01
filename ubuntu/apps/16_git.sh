#!/usr/bin/env bash
# Git config — copied (not linked) from conf/.gitconfig without the Penneo
# include, so gh/git can write to it without touching the shared file.
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Git Config"

GITCONFIG="${HOME}/.gitconfig"
# Back up only once, so a re-run never overwrites the original backup
if [[ -f "${GITCONFIG}" && ! -L "${GITCONFIG}" && ! -f "${GITCONFIG}.bak" ]]; then
    cp "${GITCONFIG}" "${GITCONFIG}.bak"
    warn "Existing ~/.gitconfig backed up to ~/.gitconfig.bak"
fi

# Drop the penneo includeIf block (header + its path line); nvim lives in
# /usr/local/bin on Ubuntu, so let PATH resolve the editor.
rm -f "${GITCONFIG}"
sed -e '/^\[includeIf "gitdir:\/home\/ilmars\/Dev\/penneo\/"\]/,+1d' \
    -e 's|editor = /usr/bin/nvim|editor = nvim|' \
    "${CONF_DIR}/.gitconfig" > "${GITCONFIG}"

log "Git config written to ${GITCONFIG}"
