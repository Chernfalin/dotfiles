xset r rate 150 100
xrdb merge ~/.Xresources
xrandr --dpi 96
setxkbmap dvp
gnome-settings-daemon &
xset -b
xbindkeys
setxkbmap -option compose:ralt
eval "$(ssh-agent)"
gnome-power-manager &
exec awesome
