#! /bin/bash
sudo nice -n -5 nohup timeout --kill-after=4m 55m clamscan -i --detect-pua=yes --heuristic-scan-precedence=yes --partition-intersection=yes --block-macros=yes --exclude-dir=/proc/ --exclude-dir=/sys/ --exclude-dir=/dev/ --exclude-dir="/lost+found/" -r / & disown
