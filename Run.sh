#!/bin/bash

actionbot="${HOME}/actionbot/src/actionbot"
dynreach="${HOME}/Documents/Processing/DynamicReaching/application.linux64/DynamicReaching"
portL=`ls /dev | egrep "cu.usbmodem\d+"`
portR='/dev/cu.usbmodemRTQ0011'
portC='/dev/cu.usbmodemfd1211'

"$dynreach" | "$actionbot" "/dev/${portL}" "$portR" "$portC"
