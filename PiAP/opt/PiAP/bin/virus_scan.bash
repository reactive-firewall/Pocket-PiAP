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
SCAN_OPTIONS=$"-i --detect-pua=yes --heuristic-scan-precedence=yes --partition-intersection=yes --block-macros=yes --exclude-dir=/proc/ --exclude-dir=/sys/ --exclude-dir=/dev/ --exclude-dir=\"/lost+found/\" -r /"
SCAN_COMMAND=$(which clamscan)
SCAN_LOG_PATH="/srv/PiAP/cache/virus_scan.log"
(sudo nice -n -5 nohup timeout --kill-after=4m 55m "${SCAN_COMMAND}" $SCAN_OPTIONS | tee "${SCAN_LOG_PATH}" 2>/dev/null >/dev/null ) & disown
exit 0 ;
