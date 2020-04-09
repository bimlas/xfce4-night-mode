#!/bin/bash

function show_usage()
{
  progname=`basename "$0"`
  echo "$progname [night|day|toggle] (defaults to 'toggle')"
  echo "$progname SUNRISE SUNSET (e.g. '8:00 18:00')"
}

function parse_args()
{
  case $# in
    0)
      echo 'toggle'
      ;;
    1)
      echo "$1"
      ;;
    2)
      _get_mode_by_time "$1" "$2"
      ;;
    *)
      exit 1
  esac
}

function _get_mode_by_time()
{
  now=`date +"%H%M"`
  sunrise="${1/:/}"
  sunset="${2/:/}"

  if [ $now -ge $sunrise -a $now -le $sunset ]; then
    echo 'day'
  else
    echo 'night'
  fi
}

function set_night_mode()
{
  current_theme=`xfconf-query -c $2 -p $3`
  if ( _is_mode_already_set "$current_theme" "$1" ); then
    exit 0
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
