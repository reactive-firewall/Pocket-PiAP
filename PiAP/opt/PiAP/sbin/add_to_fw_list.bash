#! /bin/bash
echo +${1} | sudo tee /proc/net/xt_recent/${2:-basicguestlist}
exit 0;