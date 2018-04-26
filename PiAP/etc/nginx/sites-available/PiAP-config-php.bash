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
umask 0027
if [[ ( $(php --version | grep -oF "PHP 7" | wc -l ) -gt 0 ) ]] ; then
	echo "detected PHP 7"
	if [[ ( $(grep -oF "php5" /etc/nginx/sites-available/PiAP | wc -l ) -gt 0 ) ]] ; then
		echo "Reconfigure for PHP 7" ;
		mv -vf /etc/nginx/sites-available/PiAP /etc/nginx/sites-available/PiAP.tmp ;
		sed -E -e 's/php5/php7.0/g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
	fi
	ls -1 /var/run/php* 2>/dev/null || true ; # REMOVE AFTER DEBUGGING CI
fi

exit 0;
