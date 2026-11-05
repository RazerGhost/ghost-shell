# zsh, the login shell (user's choice 2026-11-05, over fish: bash-compatible, and macOS's default).
# Our own config rather than CachyOS's (oh-my-zsh + Powerlevel10k): the same plugins straight from
# their packages, and Starship for the prompt (starship/.config/starship.toml), which takes its
# colors from the terminal's palette, so it follows the wallpaper with Ghostty.
# Machine-local additions go in ~/.config/zsh/local.zsh (gitignored, loaded last).

# Programs in your home folder (ghost, pip and cargo installs)
typeset -U path
path=(~/.local/bin ~/.cargo/bin $path)

# Terminal editor for sudoedit, git commit messages, crontab -e and anything else that opens
# $EDITOR. micro uses familiar keys: Ctrl+S save, Ctrl+Q quit.
export EDITOR=micro VISUAL=micro
# man pages through bat, with colors
export MANROFFOPT=-c MANPAGER="sh -c 'col -bx | bat -l man -p'"

# History: shared between open terminals as you type, no repeats, none for lines starting with a space
mkdir -p ~/.local/state/zsh ~/.cache/zsh
HISTFILE=~/.local/state/zsh/history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks extended_history

# Typing a folder's name goes into it; no beep
setopt auto_cd interactive_comments no_beep

# Completion (zsh-completions adds its files to the default path): case and - / _ ignored like
# fish, colors from ls
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' cache-path ~/.cache/zsh/completion
zstyle ':completion:*' use-cache on
zstyle ':completion:*:descriptions' format '[%d]' # group names, which fzf-tab switches between

# Tab opens the completions in fzf (fzf-tab): type to filter, arrows to move, Enter to take one,
# < and > for the groups; a folder shows what's in it beside the list. Loaded after compinit and
# before the plugins below, which wrap the same keys. Without it, zsh's own menu with arrow keys.
if [[ -r /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
    zstyle ':completion:*' menu no
    zstyle ':fzf-tab:*' switch-group '<' '>'
    zstyle ':fzf-tab:complete:(cd|z|ls|eza):*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
    source /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
else
    zstyle ':completion:*' menu select
fi

# Keys: emacs-style line editing; Home, End, Delete, Ctrl+arrows by word, Ctrl+Backspace a word
bindkey -e
bindkey '^[[H' beginning-of-line '^[[F' end-of-line '^[[3~' delete-char
bindkey '^[[1;5C' forward-word '^[[1;5D' backward-word '^H' backward-kill-word

# Brackets and quotes close themselves: ( gives (), and typing ) over it moves past (zsh-autopair).
# After compinit, before the highlighting below, as its README asks; it sets itself up.
[[ -r /usr/share/zsh/plugins/zsh-autopair/autopair.zsh ]] && source /usr/share/zsh/plugins/zsh-autopair/autopair.zsh

# Fish-like: suggestions from history as you type (Right arrow or End takes them), highlighting
# (loaded after everything that adds keys), and Up / Down search history for what's typed
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up '^[OB' history-substring-search-down

# fzf: Ctrl+R searches history, Ctrl+T picks a file, Alt+C goes into a folder
(( $+commands[fzf] )) && source <(fzf --zsh)
# atuin, when installed, takes Ctrl+R: a full-screen history search that can filter by folder, by
# session and by commands that failed (Ctrl+R again cycles the filter). Its Up arrow stays off,
# so Up keeps searching for what's typed (above).
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"

# A command that isn't installed says which package has it
[[ -r /usr/share/doc/pkgfile/command-not-found.zsh ]] && source /usr/share/doc/pkgfile/command-not-found.zsh

# CachyOS's listing aliases, kept from its fish config
if (( $+commands[eza] )); then
    alias ls='eza -al --color=always --group-directories-first --icons=always'
    alias la='eza -a --color=always --group-directories-first --icons=always'
    alias ll='eza -l --color=always --group-directories-first --icons=always'
    alias lt='eza -aT --color=always --group-directories-first --icons=always'
fi
alias grep='grep --color=auto'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'

(( $+commands[starship] )) && eval "$(starship init zsh)"

# Settings -> Terminal's prompt style (`terminalPrompt` in the shell's settings.json), read before
# every prompt so open terminals follow a change: pills is ~/.config/starship.toml, the others
# are in ~/.config/starship/ (settings/TerminalConfig.js `prompts`).
_ghost_prompt_style() {
    local settings=${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/settings.json style=pills
    [[ -r $settings && "$(<$settings)" =~ '"terminalPrompt": *"([a-z-]+)"' ]] && style=$match[1]
    case $style in
        minimal|two-line) export STARSHIP_CONFIG=~/.config/starship/$style.toml ;;
        *) unset STARSHIP_CONFIG ;;
    esac
}
precmd_functions=(_ghost_prompt_style $precmd_functions)

# Old prompts collapse to a plain ❯ once a command is entered, so the pills only show on the line
# you're typing in and the scrollback stays clean. zsh has no transient prompt of its own: the
# line editor runs inside a nested edit, and when it ends (Enter, Ctrl+C) the prompt is redrawn
# short before the command runs. Ctrl+D on an empty line still exits.
_ghost_collapse_prompt() {
    emulate -L zsh
    [[ $CONTEXT == start ]] || return 0
    local -i ret
    while true; do
        zle .recursive-edit
        ret=$?
        [[ $ret == 0 && $KEYS == $'\4' ]] || break
        [[ -o ignore_eof ]] || exit 0
    done
    local saved=$PROMPT saved_right=$RPROMPT
    PROMPT='%B%F{green}❯%f%b ' RPROMPT=''
    zle .reset-prompt
    PROMPT=$saved RPROMPT=$saved_right
    if (( ret )); then
        zle .send-break
    else
        zle .accept-line
    fi
    return ret
}
zle -N zle-line-init _ghost_collapse_prompt

# What a new terminal shows (Settings -> Default apps -> Terminal greeting)
[[ -o interactive && -x ~/.local/bin/ghost-greeting ]] && ~/.local/bin/ghost-greeting

# zoxide: `z proj` jumps to the folder you use most that matches (it learns from every cd),
# `zi` picks one in fzf. Last, as zoxide asks, so it sees every folder change.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

[[ -r ~/.config/zsh/local.zsh ]] && source ~/.config/zsh/local.zsh
true
