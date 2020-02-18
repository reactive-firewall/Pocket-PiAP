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
if [[ ( $(php --version | grep -oF "PHP 7" | wc -l ) -gt 0 ) ]] ; then
	echo "Detected" $(php --version | grep -oE "^[PH]{3}\s+[7.0|7.1|7.2|7.3|7.4|7.5]{3}" 2>/dev/null | head -n 1);
	PIAP_PHP_VERSION=${PIAP_PHP_VERSION:-$(php --version | grep -oE "^[PH]{3}\s+[7.0|7.1|7.2|7.3|7.4|7.5]{3}" 2>/dev/null | grep -oE "[0-9]{1}[.]{1}[0-9]{1}"| head -n 1)}
	if [[ ( $(grep -oF "php5" /etc/nginx/sites-available/PiAP | wc -l ) -gt 0 ) ]] ; then
		echo "Reconfigure for PHP ${PIAP_PHP_VERSION}" ;
		mv -vf /etc/nginx/sites-available/PiAP /etc/nginx/sites-available/PiAP.tmp ;
		# might checnge to use php --version | grep -oE "^[PH]{3}\s+[7.0|7.1|7.2|7.3]{3}"
		sed -E -e 's/php5/php'$PIAP_PHP_VERSION'/g' /etc/nginx/sites-available/PiAP.tmp 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
		sed -E -e 's/0 default_server;/0 http2 default_server;/g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
		sed -E -e 's/3 default_server;/3 http2 default_server;/g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
		sed -E -e 's/server_name;/ssl_server_name;/g' /etc/nginx/sites-available/PiAP 2>/dev/null | tee /etc/nginx/sites-available/PiAP ;
	fi
fi

exit 0;
