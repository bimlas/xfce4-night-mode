#!/bin/bash
# XFCE Night Mode controlled by Redshift
#
# https://gitlab.com/bimlas/xfce4-night-mode (main repository)
# https://github.com/bimlas/xfce4-night-mode (mirror, please star if you like the plugin)

if ( LC_ALL='C' redshift -vo 2> /dev/null | grep "Period: Daytime" > /dev/null ); then
  mode='day'
else
  mode='night'
fi

"$(dirname "$0")/xfce4-night-mode.sh" $mode | sed '/<tool>/,/<\/tool>/ d'
echo "<tool>
  Night mode defined by RedShift
  Click to toggle mode for a while
  </tool>"
