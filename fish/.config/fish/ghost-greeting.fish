# What a new terminal shows (Settings -> Default apps -> Terminal greeting, `terminalGreeting` in
# the shell's settings.json): "ghost", fastfetch with the Ghost look (fastfetch/.config/fastfetch);
# "line", one line; "none", nothing. Sourced from config.fish after CachyOS's own config, whose
# fish_greeting this replaces (the core module adds the line; conf.d loads too early for it).
function fish_greeting
    set -l mode ghost
    set -l settings ~/.local/state/quickshell/settings.json
    if test -r $settings
        set -l found (string match -rg '"terminalGreeting":\s*"(\w+)"' < $settings)
        test -n "$found"; and set mode $found
    end
    switch $mode
        case none
            return
        case line
            set -l hour (date +%H)
            set -l part evening
            if test $hour -lt 12
                set part morning
            else if test $hour -lt 18
                set part afternoon
            end
            set -l name (string split -f1 ' ' (string split -f5 : (getent passwd $USER)))
            test -n "$name"; or set name $USER
            set -l up (math --scale 0 (string split -f1 ' ' < /proc/uptime) / 60)
            set -l line "Good $part, $name" (grep -oP '^NAME="\K[^"]+' /etc/os-release) "up $up min"
            for battery in /sys/class/power_supply/BAT*
                set -a line (cat $battery/capacity)%
                break
            end
            set_color --bold blue
            echo -n $line[1]
            set_color normal
            echo " · "(string join " · " $line[2..])
        case '*'
            command -q fastfetch; and fastfetch
    end
end
