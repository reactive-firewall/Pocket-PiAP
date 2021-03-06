#! /bin/bash

# License
#
# Copyright (c) 2017-2020 Mr. Walls
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
PIAP_PHP_VERSION="${PIAP_PHP_VERSION:-5}"
if [[ ( $(php --version | grep -oF "PHP 7" | wc -l ) -gt 0 ) ]] ; then
	echo "Detected ${PIAP_PHP_VERSION:-5}";
	if [[ ( $(grep -oF "php5" /etc/nginx/sites-available/PiAP | wc -l ) -gt 0 ) ]] ; then
		echo "Reconfigure for PHP ${PIAP_PHP_VERSION}" ;
		mv -vf /etc/nginx/sites-available/PiAP /etc/nginx/sites-available/PiAP.tmp ;
		# might change to use php --version | grep -oE "^[PH]{3}\s+[7.0|7.1|7.2|7.3]{3}"
		sed -E -e 's/php5/php'"${PIAP_PHP_VERSION}"'/g' /etc/nginx/sites-available/PiAP.tmp 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
		sed -E -e 's/0 default_server;/0 http2 default_server;/g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
		sed -E -e 's/3 default_server;/3 http2 default_server;/g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
		sed -E -e 's/server_name;/ssl_server_name;/g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
	fi
	# can find real socket by 
	PIAP_PHP_SOCK=$(find /etc/ -ipath "*/php*" -a -iname "*.conf*" -print0 2>/dev/null | xargs -0 -L1 -I{} grep -F "listen" {} | grep -oE "^\s*listen\s*=\s*.*" | cut -d = -f 2- | head -n 1 | sed -E -e 's/^([[:space:]]+){1}//g') ;
	if [[ ( $(echo "${PIAP_PHP_SOCK}" | grep -oF ".sock" | wc -l ) -gt 0 ) ]] ; then
		sed -E -e 's/fastcgi_pass unix:/fastcgi_pass unix:'"${PIAP_PHP_SOCK}"'; # /g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
	else
		sed -E -e 's/fastcgi_pass unix:/fastcgi_pass '"${PIAP_PHP_SOCK}"'; # /g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
	fi
fi

exit 0;
