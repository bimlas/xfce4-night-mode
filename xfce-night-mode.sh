#!/bin/bash

TEXT='<span size="xx-large">&#x262F;</span>'
SUNRISE='8:00'
SUNSET='18:00'

function show_usage()
{
  progname=`basename "$0"`
  echo "$progname [night|day|toggle]"
  echo "Without parameters it will set dark theme from $SUNSET to $SUNRISE"
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
  now=`date +"%H%M"`

  if [ $now -ge "${SUNRISE/:/}" -a $now -le "${SUNSET/:/}" ]; then
    echo 'day'
  else
    echo 'night'
  fi
}

function set_night_mode()
{
  current_theme=`xfconf-query -c $2 -p $3`
  if ( _is_mode_already_set "$current_theme" "$1" ); then
    return
  fi

  new_theme=`_set_$1 "$current_theme" 2> /dev/null`
  if [ $? != 0 ]; then
    show_usage
    exit 1
  fi

  xfconf-query -c $2 -p $3 -s "$new_theme"
}

function _is_mode_already_set()
{
  if ( _is_dark "$1" ) && [ "$2" = "night" ]; then
    exit 0
  fi
  if ! ( _is_dark "$1" ) && [ "$2" = "day" ]; then
    exit 0
  fi
  exit 1
}

function _set_toggle()
{
  if ( _is_dark "$1" ); then
    _set_day "$1"
  else
    _set_night "$1"
  fi
}

function _is_dark()
{
  echo "$1" | grep '\-dark$' > /dev/null
}

function _set_day()
{
  echo "${1%-dark}"
}

function _set_night()
{
  if ( _is_dark "$1" ); then
    echo "$1"
  else
    echo "$1-dark"
  fi
}

mode=`parse_args $@`
if [ $? != 0 ]; then
  show_usage
  exit 1
fi

# GTK theme
set_night_mode $mode xsettings /Net/ThemeName

# Icon theme
set_night_mode $mode xsettings /Net/IconThemeName

# Window manager theme
# set_night_mode $mode xfwm4 /general/theme

echo "<txt>$TEXT</txt>"
echo "<txtclick>$0 toggle</txtclick>"
echo "<tool>Night mode: $SUNSET - $SUNRISE</tool>"
