# fish stays installed as a fallback (zsh is the login shell). Its greeting is the same script as
# zsh's (bin/.local/bin/ghost-greeting, Settings -> Default apps -> Terminal greeting). Sourced
# from config.fish after CachyOS's own config, whose fish_greeting this replaces (the core module
# adds the line; conf.d loads too early for it).
function fish_greeting
    ~/.local/bin/ghost-greeting
end
