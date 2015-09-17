
#!/bin/bash
#++++++++++++++++
# Monitor Switch
#
# Moves currently focused window from one monitor to the other.
# Designed for a system with two monitors.
# Script should be triggered using a keyboard shortcut.
#++++++++++++++++

# width of left monitor
w_l_monitor=1024

# focus on active window
window=`xdotool getactivewindow`

# get active window position and width
x=`xwininfo -id $window | grep "Absolute upper-left X" | awk '{print $4}'`
y_abs=`xwininfo -id $window | grep "Absolute upper-left Y" | awk '{print $4}'`
y_rel=`xwininfo -id $window | grep "Relative upper-left Y" | awk '{print $4}'`
w=`xwininfo -id $window | grep "Width" | awk '{print $2}'`

# unmaximize
wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz

# calculate new x position
if [ "$x" -lt "$w_l_monitor" ]; then
# window on left monitor
new_x=$(($x+$w_l_monitor))
else
# window on right monitor
new_x=$(($x-$w_l_monitor))
fi

#move window. Need to subtract the relative y-position.
new_y=$(($y_abs-$y_rel))
xdotool windowmove $window $new_x $new_y

if [ "$w" -eq "$w_l_monitor" ]; then
# maximize
wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
fi
