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

# Completion (zsh-completions adds its files to the default path): a menu to move through with the
# arrow keys, case and - / _ ignored like fish, colors from ls
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' cache-path ~/.cache/zsh/completion
zstyle ':completion:*' use-cache on

# Keys: emacs-style line editing; Home, End, Delete, Ctrl+arrows by word, Ctrl+Backspace a word
bindkey -e
bindkey '^[[H' beginning-of-line '^[[F' end-of-line '^[[3~' delete-char
bindkey '^[[1;5C' forward-word '^[[1;5D' backward-word '^H' backward-kill-word

# Fish-like: suggestions from history as you type (Right arrow or End takes them), highlighting
# (loaded after everything that adds keys), and Up / Down search history for what's typed
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up '^[OB' history-substring-search-down

# fzf: Ctrl+R searches history, Ctrl+T picks a file, Alt+C goes into a folder
(( $+commands[fzf] )) && source <(fzf --zsh)

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

# What a new terminal shows (Settings -> Default apps -> Terminal greeting)
[[ -o interactive && -x ~/.local/bin/ghost-greeting ]] && ~/.local/bin/ghost-greeting

[[ -r ~/.config/zsh/local.zsh ]] && source ~/.config/zsh/local.zsh
true
