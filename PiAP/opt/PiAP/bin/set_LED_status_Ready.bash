#! /bin/bash

# License
#
# Copyright (c) 2017-2018 Mr. Walls
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#

# need to add locking for states

# PIAP_BLINK_LED - the LED to blink (valid values = 0 - 20 default: 0)
# PIAP_BLINK_COUNT - the count to blink (valid values = 0 - 1000 (where 0 is ongoing) default: 0)
PIAP_BLINK_COUNT=1
PIAP_BIN_PATH=$(dirname $0)
# flash on and off once
${PIAP_BIN_PATH}/blink_LED.bash 0 ${PIAP_BLINK_COUNT:-1} ; wait ;
${PIAP_BIN_PATH}/blink_LED.bash 1 ${PIAP_BLINK_COUNT:-1} ; wait ;
REG_COLON=$":"


echo "default-on" | sudo tee /sys/class/leds/led0/trigger 2>/dev/null > /dev/null || true ;
echo "none" | sudo tee /sys/class/leds/led1/trigger 2>/dev/null > /dev/null || true ;
echo 255 | sudo tee "/sys/class/leds/led0${REG_COLON}${REG_COLON}assoc/brightness" 2>/dev/null > /dev/null || true ;
#echo 0 | sudo tee "/sys/class/leds/led1${REG_COLON}${REG_COLON}assoc/brightness" 2>/dev/null > /dev/null || true ;


# heristic for wlan1 with canna-kit usb wifi chips
if [[ ( $(sudo ls -1 /sys/class/leds/rt*usb-phy1${REG_COLON}${REG_COLON}assoc/brightness | wc -l | cut -d\  -f 1 2>/dev/null || echo -n 0 ) -gt 0 ) ]] ; then
	echo "none" | sudo tee "/sys/class/leds/rt2800usb-phy1${REG_COLON}${REG_COLON}assoc/trigger" 2>/dev/null > /dev/null || true ;
	echo 255 | sudo tee "/sys/class/leds/rt2800usb-phy1${REG_COLON}${REG_COLON}assoc/brightness" 2>/dev/null > /dev/null || true ;
fi
exit 0;
