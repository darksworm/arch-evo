#!/usr/bin/env bash
# PipeWire audio stack (replaces PulseAudio)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "PipeWire Audio"

pac_install pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol

enable_user_service pipewire.service
enable_user_service pipewire-pulse.service
enable_user_service wireplumber.service

log "PipeWire audio stack installed"
