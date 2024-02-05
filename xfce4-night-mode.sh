#!/bin/bash
# XFCE Night Mode: Switch between light and dark variants of a theme
#
# https://github.com/bimlas/xfce4-night-mode (please star if you like the plugin)

function show_usage()
{
  progname="$(basename $0)"
  echo "$progname [night|day|toggle]"
  echo "Without parameters it will set dark theme from $SUNSET to $SUNRISE"
  echo 'Use `xfce4-settings-editor` -> `night-mode` to modify settings'
}

function parse_args()
{
  case $# in
    0)
      _get_mode_by_time
      ;;
    1)
      echo "$1"
      ;;
    *)
      exit 1
  esac
}

function _get_mode_by_time()
{
  now="$(date '+%H%M')"

  if [ $now -ge "${SUNRISE/:/}" -a $now -le "${SUNSET/:/}" ]; then
    echo 'day'
  else
    echo 'night'
  fi
}


#######################################
# Set theme to requested theme if it is not already set
# Globals:
#   GTK_LIGHT
#   GTK_DARK
#   ICON_LIGHT
#   ICON_DARK
#   CURSOR_LIGHT
#   CURSOR_DARK
#   WM_LIGHT
#   WM_DARK
# Arguments:
#   Channel: xfconf channel to change
#   Property: property of that xfconf channel to change
#   Variable name: global that contains the name of the requested theme
# Outputs:
#   None
#######################################
function set_theme()
{
  current_theme="$(xfconf-query --channel $1 --property $2)"
  declare -n target_theme="$3"

  if [ "$current_theme" = "$target_theme" ]; then
    return
  fi

  xfconf-query --channel "$1" --property "$2" --set "$target_theme"

  if [ $? != 0 ]; then
    show_usage
    exit 1
  fi

  if [ "$2" = "/Net/ThemeName" ]
  then
    gsettings set org.gnome.desktop.interface gtk-theme "$target_theme"
  fi
}

function get_config()
{
  result="$(xfconf-query --channel 'night-mode' --property /$1 2> /dev/null)"
  if ! [ "$result" ]; then
    result="$3"
    xfconf-query --channel 'night-mode' --property "/$1" --set "$result" --create --type "$2"
  fi

  echo "$result"
}

function set_config()
{
  xfconf-query --channel 'night-mode' --property "/$1" --set "$3" --create --type "$2"
}

TEXT="$(get_config 'text' 'string' '<span size="xx-large">&#x262F;</span>')"
SUNRISE="$(get_config 'sunrise' 'string' '7:30')"
SUNSET="$(get_config 'sunset' 'string' '18:00')"
GTK_LIGHT="$(get_config 'Light/GtkTheme' 'string' $(xfconf-query --channel xsettings --property /Net/ThemeName))"
GTK_DARK="$(get_config 'Dark/GtkTheme' 'string' $(xfconf-query --channel xsettings --property /Net/ThemeName))"
ICON_LIGHT="$(get_config 'Light/IconTheme' 'string' $(xfconf-query --channel xsettings --property /Net/IconThemeName))"
ICON_DARK="$(get_config 'Dark/IconTheme' 'string' $(xfconf-query --channel xsettings --property /Net/IconThemeName))"
CURSOR_LIGHT="$(get_config 'Light/CursorTheme' 'string' $(xfconf-query --channel xsettings --property /Gtk/CursorThemeName))"
CURSOR_DARK="$(get_config 'Dark/CursorTheme' 'string' $(xfconf-query --channel xsettings --property /Gtk/CursorThemeName))"
WM_LIGHT="$(get_config 'Light/WindowManagerTheme' 'string' $(xfconf-query --channel xfwm4 --property /general/theme))"
WM_DARK="$(get_config 'Dark/WindowManagerTheme' 'string' $(xfconf-query --channel xfwm4 --property /general/theme))"
USERSCRIPT_LIGHT="$(get_config 'Light/UserScript' 'string')"
USERSCRIPT_DARK="$(get_config 'Dark/UserScript' 'string')"

mode="$(parse_args $@)"

if [ $? != 0 ]; then
  show_usage
  exit 1
fi

if [ "$mode" = "toggle" ]; then
  current="$(get_config 'active' 'string' 'day')"
  case "$current" in
    day)
      mode='night'
      ;;
    night)
      mode='day'
      ;;
    *)
      exit 1
  esac
fi

case "$mode" in
  day)
    suffix='LIGHT'
    ;;
  night)
    suffix='DARK'
    ;;
  *)
    exit 1
esac

# GTK theme
set_theme 'xsettings' '/Net/ThemeName' "GTK_$suffix"

# Icon theme
set_theme 'xsettings' '/Net/IconThemeName' "ICON_$suffix"

# Cursor theme
set_theme 'xsettings' '/Gtk/CursorThemeName' "CURSOR_$suffix"

# Window manager theme
set_theme 'xfwm4' '/general/theme' "WM_$suffix"

set_config 'active' 'string' "$mode"

# Execute user script to change wallpaper, terminal theme, etc.
userscript="USERSCRIPT_$suffix"
if [ ! -z "${!userscript}" ]; then
  XFCE_NIGHT_MODE="$mode" eval "${!userscript}" 2>&1 > /dev/null
fi

echo "<txt>$TEXT</txt>"
echo "<txtclick>$0 toggle</txtclick>"
echo "<tool>
  Night mode: $SUNSET - $SUNRISE
  Click to toggle mode for a while
  Use \`xfce4-settings-editor\` -> \`night-mode\` to modify settings

  To find out what values to enter, set the color schemes you want and copy
  them from the appropriate location:

  * GTK theme: \`xsettings/Net/ThemeName\`
  * Icon theme: \`xsettings/Net/IconThemeName\`
  * Cursor theme: \`xsettings/Gtk/CursorThemeName\`
  * Window manager theme: \`xfwm4/general/theme\`
</tool>"
