#! /bin/bash

# License
#
# Copyright (c) 2017 Mr. Walls
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

# should check inputs - CWE-20
# PIAP_BLINK_LED - the LED to blink (valid values = 0 - 20 default: 0)
PIAP_BLINK_LED=${1:-0}
# PIAP_BLINK_COUNT - the count to blink (valid values = 0 - 1000 (where 0 is ongoing) default: 10)
PIAP_BLINK_COUNT=${2:-10}

if [[ ( ${PIAP_BLINK_COUNT:-10} -gt 0 ) ]] ; then
	for BLINK_COUNT in $(seq 0 ${2:-10}) ; do
		echo $(head -n 1 /sys/class/leds/led${PIAP_BLINK_LED:-0}/max_brightness ) | sudo tee /sys/class/leds/led${PIAP_BLINK_LED:-0}/brightness 1>&2 2>/dev/null ;
		sleep 0.05s
		echo 0 | sudo tee /sys/class/leds/led${PIAP_BLINK_LED:-0}/brightness 1>&2 2>/dev/null ;
	done
elif [[ ( ${PIAP_BLINK_COUNT:-10} -ge 0 ) ]] ; then
	echo none | sudo tee /sys/class/leds/led${PIAP_BLINK_LED:-0}/trigger 1>&2 2>/dev/null ;
	echo 0 | sudo tee /sys/class/leds/led${PIAP_BLINK_LED:-0}/brightness 1>&2 2>/dev/null ;
	echo none | sudo tee /sys/class/leds/led${PIAP_BLINK_LED:-0}/trigger 1>&2 2>/dev/null ;
else
	echo heartbeat | sudo tee /sys/class/leds/led${PIAP_BLINK_LED:-0}/trigger 1>&2 2>/dev/null ;
fi
exit 0;
