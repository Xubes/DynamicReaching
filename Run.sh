#!/bin/bash

robocommander="${HOME}/Documents/workspace/robocommander/Release/robocommander"
dynreach="${HOME}/Documents/Processing/DynamicReaching/application.linux64/DynamicReaching"
portL="/dev/`ls /dev | egrep 'cu.usbmodem\d+'`"
portL=' '
#portR='/dev/cu.usbmodemRTQ0011'
portR=' '
portC='/dev/cu.usbmodemfd1241'

"$dynreach" | "$robocommander" "/dev/${portL}" "$portR" "$portC"
