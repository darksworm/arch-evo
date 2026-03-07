export EDITOR=nvim

# Start with basic vi mode (instant)
bindkey -v

# Lazy-load zsh-vi-mode on first Escape press
_zvm_lazy_loaded=0
_zvm_plugin_path="/usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

_load_zvm() {
  if [[ $_zvm_lazy_loaded -eq 0 ]] && [[ -f "$_zvm_plugin_path" ]]; then
    _zvm_lazy_loaded=1
    export ZVM_INIT_MODE=sourcing
    # Re-bind fzf history search after zvm loads (zvm overrides ctrl+r)
    zvm_after_init_commands+=('
      [[ -f /usr/share/zsh/plugins/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh ]] &&
        source /usr/share/zsh/plugins/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh
    ')
    source "$_zvm_plugin_path"
    zle vi-cmd-mode
  else
    zle vi-cmd-mode
  fi
}

zle -N _load_zvm
bindkey '\e' _load_zvm
