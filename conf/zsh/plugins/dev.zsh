export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# mise (version manager for java, node, python, etc.)
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# Lazy-load direnv: only initialize when entering a directory with .envrc
_direnv_hook_initialized=0

_lazy_direnv_hook() {
  if [[ $_direnv_hook_initialized -eq 0 ]]; then
    if [[ -f .envrc ]] || [[ -f .env ]]; then
      _direnv_hook_initialized=1
      emulate zsh -c "$(direnv hook zsh)"
      _direnv_hook
    fi
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _lazy_direnv_hook

direnv-init() {
  if [[ $_direnv_hook_initialized -eq 0 ]]; then
    _direnv_hook_initialized=1
    emulate zsh -c "$(direnv hook zsh)"
    _direnv_hook
  fi
}

# Cache zoxide init output (avoids ~240ms subprocess call on cold cache)
_zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide-init.zsh"
if [[ ! -f "$_zoxide_cache" ]]; then
  mkdir -p "${_zoxide_cache:h}"
  zoxide init zsh > "$_zoxide_cache"
  zcompile "$_zoxide_cache"
fi
source "$_zoxide_cache"
unset _zoxide_cache

# Alias fnm to mise (mise is the active version manager)
alias fnm=mise

# Pritunl VPN
alias vpn-on='pritunl-client start mupovw7mbmn2sbgg'
alias vpn-off='pritunl-client stop mupovw7mbmn2sbgg'
