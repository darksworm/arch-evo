# arch-evo — Ubuntu port

Installs the arch-evo desktop and tooling on an existing Ubuntu (26.04)
install. Configs in `../conf` and helpers in `../bin` are shared with the Arch
installer; only the install scripts here differ.

```
bash ubuntu/install.sh              # run everything not yet completed
bash ubuntu/install.sh --only 11    # run one script
bash ubuntu/install.sh --from 09    # resume from a script
```

Run as your normal user (not via sudo) — scripts call sudo when needed.
Completion markers live in `~/.local/state/arch-evo-ubuntu/completed/`; delete
one to re-run that script.

## Where packages come from

| Source | What |
|---|---|
| apt | most CLI tools, zsh plugins, foot, tmux, keyd, waybar, fuzzel, dunst, fprintd, fonts/icons/cursor |
| `ppa:cppiber/hyprland` | hyprland (Lua config needs > 0.53), hyprlock, hypridle, hyprsunset, portal |
| vendor apt repos | Docker CE, Spotify |
| mise (`conf/mise/ubuntu-tools.toml`) | uv, ghq, helm, kustomize, krew, dive, kubectl, argo-rollouts, kubelogin, yazi |
| upstream releases | neovim, Zen, Vesktop .deb, matuwall, hyprdynamicmonitors, adw-gtk3, JetBrains Mono Nerd |
| git / source | zsh-vi-mode, fast-syntax-highlighting (clones), awww (cargo build) |
| uv tool | pyprland |

## Differences from Arch

- Hyprland is chosen at the GDM login screen; GNOME remains available.
- SSH uses GNOME's `gcr-ssh-agent` instead of `ssh-agent.service` + `pass` askpass.
- `~/.gitconfig` is a copy (minus the Penneo include), not a symlink.
- Not ported: Penneo DNS/certs/office-log, SentinelOne, work apps, 1Password,
  power/webcam udev rules, fanmode-auto, WirePlumber A2DP conf, blueman.
