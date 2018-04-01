#! /bin/bash
SCAN_OPTIONS='-i --detect-pua=yes --heuristic-scan-precedence=yes --partition-intersection=yes --block-macros=yes --exclude-dir=/proc/ --exclude-dir=/sys/ --exclude-dir=/dev/ --exclude-dir="/lost+found/" -r /'
SCAN_COMMAND=$(which clamscan)
SCAN_LOG_PATH="/srv/PiAP/cache/virus_scan.log"
(sudo nice -n -5 nohup timeout --kill-after=4m 55m ${SCAN_COMMAND} $SCAN_OPTIONS | tee ${SCAN_LOG_PATH} 2>/dev/null >/dev/null ) & disown
exit 0 ;
