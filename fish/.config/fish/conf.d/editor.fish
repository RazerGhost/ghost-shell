# Terminal editor for sudoedit, git commit messages, crontab -e and anything else that
# opens $EDITOR. micro uses familiar keys: Ctrl+S save, Ctrl+Q quit.
# Fish loads every file in conf.d at startup, so CachyOS's config.fish stays untouched.
set -gx EDITOR micro
set -gx VISUAL micro
