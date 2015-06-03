#!/bin/bash
# Run robocontroller Processing program and pipe it to actionbot.  Supply the three usbmodem ports to actionbot.  Requires FTDI serial port drivers.
cd "/users/shohanhasan/Code/Processing/DynamicReaching"
cd "application.linux64" && ./DynamicReaching | ../actionbot `ls -d -1 /dev/*.* | grep -E "tty.usbmodem(RTQ|fd)?\d+" | xargs -n 3`
