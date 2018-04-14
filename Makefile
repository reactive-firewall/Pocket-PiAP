#!/usr/bin/env make -f

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


ifeq "$(ECHO)" ""
	ECHO=echo
endif

ifeq "$(LINK)" ""
	LINK=ln -sf
endif

ifeq "$(MAKE)" ""
	MAKE=`which make`
endif

ifeq "$(WAIT)" ""
	WAIT=wait
endif

ifeq "$(CP)" ""
	CP=cp -vpb
endif

ifeq "$(CPDIR)" ""
	CPDIR=$(CP)R
endif

ifeq "$(CHOWN)" ""
	CHOWN=`which chown` -vf
	ifeq "$(FILE_OWN)" ""
		FILE_OWN=pocket-admin:pocket
	endif
	ifeq "$(WEB_OWN)" ""
		WEB_OWN=pocket-admin:pocket-www
	endif
	ifeq "$(SYS_OWN)" ""
		SYS_OWN=root:root
	endif
endif

ifeq "$(RM)" ""
	RM=rm -f
endif

ifeq "$(RMDIR)" ""
	RMDIR=$(RM)R
endif

ifeq "$(INSTALL)" ""
	INSTALL=`which install`
	ifeq "$(INST_OWN)" ""
		INST_OWN=-C -o pocket-admin -g pocket
	endif
	ifeq "$(INST_WEB_OWN)" ""
		INST_WEB_OWN=-C -o pocket-admin -g pocket-www
	endif
	ifeq "$(INST_DNS_OWN)" ""
		INST_DNS_OWN=-C -o pocket-admin -g pocket-dns
	endif
	ifeq "$(INST_ROOT_OWN)" ""
		INST_ROOT_OWN=-C -o root -g root
	endif
	ifeq "$(INST_OPTS)" ""
		INST_OPTS=-m 750
	endif
	ifeq "$(INST_WEB_OPTS)" ""
		INST_WEB_OPTS=-m 644
	endif
	ifeq "$(INST_FILE_OPTS)" ""
		INST_FILE_OPS=-m 640
	endif
	ifeq "$(INST_DIR_OPTS)" ""
		INST_DIR_OPTS=-m 750 -d
	endif
	ifeq "$(INST_PUB_DIR_OPTS)" ""
		INST_PUB_DIR_OPTS=-m 755 -d
	endif
endif

ifeq "$(LOG)" ""
	LOG=no
endif

ifeq "$(LOG)" "no"
	QUIET=@
endif

SHELL=/bin/bash

PHONY: must_be_root cleanup

build:
	$(QUIET)$(ECHO) "No need to build. Try make -f Makefile install"

init:
	$(QUIET)$(ECHO) "$@: Done."

install: install-dsauth install-webroot install-optroot install-wpa-actions install-hostapd-actions install-optsbin install-optbin configure-PiAP-sudoers configure-PiAP-dnsmasq install-pifi configure-PiAP-keyring must_be_root
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile install
	$(QUITE)$(WAIT)
	$(QUIET)$(ECHO) "$@: Done."

install-optroot: ./PiAP must_be_root
	$(QUIET)addgroup --system --force-badname pocket 2>/dev/null || true
	$(QUIET)addgroup --system --force-badname pocket-admin 2>/dev/null || true
	$(QUIET)addgroup --system --force-badname pocket-www 2>/dev/null || true
	$(QUIET)addgroup --system --force-badname pocket-dns 2>/dev/null || true
	$(QUIET)adduser --system --disabled-password --home /opt/PiAP/ --shell /bin/bash --force-badname --no-create-home --group pocket  pocket 2>/dev/null || true
	$(QUIET)adduser --system --disabled-password --home /opt/PiAP/ --shell /bin/bash --force-badname --no-create-home --group pocket-admin pocket-admin 2>/dev/null || true
	$(QUIET)adduser --system --disabled-password --home /srv/PiAP/ --shell /bin/bash --force-badname --no-create-home --group pocket-www pocket-www 2>/dev/null || true
	$(QUIET)adduser --system --disabled-password --home /usr/lib/misc --shell /bin/bash --force-badname --no-create-home --group pocket-dns pocket-dns 2>/dev/null || true
	$(QUIET)usermod -a -G pocket-dns,pocket-www,pocket,netdev pocket-admin 2>/dev/null || true
	$(QUIET)usermod -a -G pocket,www-data pocket-www 2>/dev/null || true
	$(QUIET)usermod -a -G pocket pocket-dns 2>/dev/null || true
	$(QUIET)usermod -a -G pocket-www www-data 2>/dev/null || true
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/
	$(QUIET)$(ECHO) "$@: Done."

uninstall-optroot: /opt/PiAP/ uninstall-wpa-actions uninstall-hostapd-actions uninstall-optbin uninstall-optsbin must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/ || true
	$(QUIET)$(ECHO) "$@: Done."

/opt/PiAP/: /opt/ must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/
	$(QUIET)$(ECHO) "$@: Done."

/opt/: must_be_root
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_PUB_DIR_OPTS) /opt/
	$(QUIET)$(ECHO) "$@: Done."

install-optbin: install-optroot must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/bin
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/bin/blink_LED.bash /opt/PiAP/bin/blink_LED.bash
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/bin/virus_scan.bash /opt/PiAP/bin/virus_scan.bash
	$(QUIET)$(ECHO) "$@: Done."

uninstall-optbin: must_be_root
	$(QUIET)$(RM) /opt/PiAP/bin/blink_LED.bash 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/bin/virus_scan.bash 2>/dev/null || true
	$(QUIET)$(RMDIR) /opt/PiAP/bin 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

install-optsbin: install-optroot must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/sbin
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/sbin/kick_client /opt/PiAP/sbin/kick_client
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/sbin/autosign_client /opt/PiAP/sbin/autosign_client
	$(QUIET)$(ECHO) "$@: Done."

uninstall-optsbin: must_be_root
	$(QUIET)$(RM) /opt/PiAP/sbin/kick_client 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/sbin/autosign_client 2>/dev/null || true
	$(QUIET)$(RMDIR) /opt/PiAP/sbin 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."
	
install-wpa-actions: install-optroot must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/wpa_actions
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/list_networks /opt/PiAP/wpa_actions/list_networks
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/status
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/add_network
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/add_network_primitive
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/clear_blacklist
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/count_networks
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/del_network_primitive
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/list_blacklist
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/load_config
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/log_msg
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/ping_wpa
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/readycheck
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/save_config
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/select_network
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/set_network_primitive
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/toggle_blacklist
	$(QUIET)$(ECHO) "$@: Done."

uninstall-wpa-actions: must_be_root
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/list_networks 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/status 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/add_network 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/add_network_primitive 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/clear_blacklist 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/count_networks 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/del_network_primitive 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/list_blacklist 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/load_config 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/log_msg 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/ping_wpa 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/readycheck 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/save_config 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/select_network 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/set_network_primitive 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/toggle_blacklist 2>/dev/null || true
	$(QUIET)$(RMDIR) /opt/PiAP/wpa_actions 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

install-hostapd-actions: install-optroot must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/hostapd_actions
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/hostapd_actions/clients /opt/PiAP/hostapd_actions/clients
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/hostapd_actions/deauth /opt/PiAP/hostapd_actions/deauth
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/hostapd_actions/disassociate /opt/PiAP/hostapd_actions/disassociate
	$(QUIET)$(ECHO) "$@: Done."

uninstall-hostapd-actions: must_be_root
	$(QUIET)$(RM) /opt/PiAP/hostapd_actions/clients 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/hostapd_actions/deauth 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/hostapd_actions/disassociate 2>/dev/null || true
	$(QUIET)$(RMDIR) /opt/PiAP/hostapd_actions 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

install-dsauth: install-optroot must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/srv/dsauth.py /srv/PiAP/dsauth.py
	$(QUIET)$(ECHO) "$@: Done."

uninstall-dsauth: must_be_root
	$(QUIET)$(RM) /srv/PiAP/dsauth.py 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

install-pifi: must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_FILE_OPTS) ./PiAP/etc/init.d/wirelessWiFi /etc/init.d/wirelessWiFi
	$(QUIET)update-rc.d wirelessWiFi enable 2>/dev/null || update-rc.d start 30 2345 . stop 0 1 6 wirelessWiFi 2>/dev/null ; wait ;
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_FILE_OPTS) ./PiAP/etc/init.d/wirelessPiAP /etc/init.d/wirelessPiAP
	$(QUIET)update-rc.d wirelessPiAP enable 2>/dev/null || update-rc.d start 30 2345 . stop 0 1 6 wirelessPiAP 2>/dev/null ; wait ;
	$(QUIET)$(ECHO) "$@: Done."

uninstall-pifi: must_be_root
	$(QUIET)$(RM) /etc/init.d/wirelessPiAP 2>/dev/null || true
	$(QUIET)$(RM) /etc/init.d/wirelessWiFi 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

/etc/ssl/PiAPCA/private/PiAP_CA.key: configure-PiAP-keyring must_be_root
	$(QUIET)dd if=/dev/hwrng bs=1024 count=4096 of=/tmp/.rand_seed.data 2>/dev/null || true
	$(QUIET)openssl genrsa -rand /tmp/.rand_seed.data -out /etc/ssl/PiAPCA/private/PiAP_CA.key 4096 2>/dev/null || openssl genrsa -out /etc/ssl/PiAPCA/private/PiAP_CA.key 4096 2>/dev/null || true
	$(QUITE)$(WAIT)
	$(QUITE)$(CHOWN) $(SYS_OWN) /etc/ssl/PiAPCA/private/PiAP_CA.key || exit 2
	$(QUIET)rm -f /tmp/.rand_seed.data 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Generated."

/etc/ssl/PiAPCA/private/PiAP_CA.csr: /etc/ssl/PiAPCA/private/PiAP_CA.key must_be_root
	$(QUIET)openssl req -new -outform PEM -out /etc/ssl/PiAPCA/private/PiAP_CA.csr -key /etc/ssl/PiAPCA/private/PiAP_CA.key -subj "/CN=Pocket\ PiAP\ CA/OU=PiAP\ Root/O=PiAP\ Network/" 2>/dev/null
	$(QUITE)$(WAIT)
	$(QUITE)$(CHOWN) $(SYS_OWN) /etc/ssl/PiAPCA/private/PiAP_CA.key || exit 2
	$(QUIET)$(ECHO) "$@: Requested."

/etc/ssl/PiAPCA/PiAP_CA.pem: /etc/ssl/PiAPCA/private/PiAP_CA.csr must_be_root
	$(QUIET)openssl x509 -req -outform PEM -keyform PEM -in /etc/ssl/PiAPCA/private/PiAP_CA.csr -out /etc/ssl/PiAPCA/PiAP_CA.pem -days 180  -signkey /etc/ssl/PiAPCA/private/PiAP_CA.key -extfile /etc/ssl/PiAP_keyring.cfg -extensions PiAP_CA_cert 2>/dev/null
	$(QUITE)$(WAIT)
	$(QUIET)$(ECHO) "$@: Self-Signed."

/etc/ssl/certs/ssl-cert-CA-nginx.pem: /etc/ssl/PiAPCA/PiAP_CA.pem must_be_root
	$(QUIET)ln -sf ../PiAPCA/PiAP_CA.pem /etc/ssl/certs/ssl-cert-CA-nginx.pem 2>/dev/null || true
	$(QUITE)$(WAIT)
	$(QUIET)$(ECHO) "$@: Installed."

/etc/ssl/PiAPCA/private/PiAP_SSL.key: /etc/ssl/certs/ssl-cert-CA-nginx.pem must_be_root
	$(QUIET)dd if=/dev/hwrng bs=1024 count=4096 of=/tmp/.rand_seed.data 2>/dev/null || true
	$(QUIET)openssl genrsa -rand /tmp/.rand_seed.data -out /etc/ssl/PiAPCA/private/PiAP_SSL.key 4096 2>/dev/null || openssl genrsa -out /etc/ssl/PiAPCA/private/PiAP_SSL.key 2048 2>/dev/null || exit 3
	$(QUITE)$(WAIT)
	$(QUITE)$(CHOWN) $(WEB_OWN) /etc/ssl/PiAPCA/private/PiAP_SSL.key || exit 2
	$(QUIET)rm -f /tmp/.rand_seed.data 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Generated."

/etc/ssl/PiAPCA/private/PiAP_SSL.csr: /etc/ssl/PiAPCA/private/PiAP_SSL.key must_be_root
	$(QUIET)openssl req -new -outform PEM -out /etc/ssl/PiAPCA/private/PiAP_SSL.csr -key /etc/ssl/PiAPCA/private/PiAP_SSL.key -subj "/CN=pocket.piap.local/OU=PiAP\ SSL/O=PiAP\ Network/" 2>/dev/null
	$(QUITE)$(WAIT)
	$(QUITE)$(CHOWN) $(WEB_OWN) /etc/ssl/PiAPCA/private/PiAP_SSL.csr || exit 2
	$(QUIET)$(ECHO) "$@: Requested."

/etc/ssl/PiAPCA/certs/PiAP_SSL.pem: configure-PiAP-keyring /etc/ssl/PiAPCA/private/PiAP_SSL.csr /etc/ssl/PiAPCA/private/PiAP_CA.key must_be_root
	$(QUIET)openssl ca -config /etc/ssl/PiAP_keyring.cfg -days 180 -in /etc/ssl/PiAPCA/private/PiAP_SSL.csr -extfile /etc/ssl/PiAP_keyring.cfg -extensions PiAP_server_cert -batch | fgrep --after-context=800 -e "-----BEGIN CERTIFICATE-----" | tee /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null > /dev/null || true
	$(QUITE)$(WAIT)
	$(QUITE)$(CHOWN) $(WEB_OWN) /etc/ssl/PiAPCA/certs/PiAP_SSL.pem || exit 2
	$(QUIET)$(ECHO) "$@: Signed."

/etc/ssl/certs/ssl-cert-nginx.pem: configure-PiAP-keyring /etc/ssl/PiAPCA/certs/PiAP_SSL.pem /etc/ssl/certs/ssl-cert-CA-nginx.pem must_be_root
	$(QUITE)$(WAIT)
	$(QUIET)ln -sf ../PiAPCA/certs/PiAP_SSL.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Installed."

configure-httpd: install-optroot /etc/nginx /etc/ssl/certs/ssl-cert-nginx.pem must_be_root
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/nginx/fastcgi.conf /etc/nginx/fastcgi.conf 2>/dev/null
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/nginx/fastcgi_params /etc/nginx/fastcgi_params 2>/dev/null
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/nginx/nginx.conf /etc/nginx/nginx.conf 2>/dev/null
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/nginx/proxy_params /etc/nginx/proxy_params 2>/dev/null || true
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/nginx/snippets/fastcgi-php.conf /etc/nginx/snippets/fastcgi-php.conf 2>/dev/null
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/nginx/snippets/pocket_ssl.conf /etc/nginx/snippets/pocket_ssl.conf 2>/dev/null
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/nginx/sites-available/PiAP /etc/nginx/sites-available/PiAP 2>/dev/null
	$(QUIET)ln -sf /etc/nginx/sites-available/PiAP /etc/nginx/sites-enabled/PiAP 2>/dev/null || true
	$(QUITE)$(WAIT)
	$(QUIET)$(ECHO) "$@: Done."

remove-httpd: must_be_root
	$(QUIET)$(RM) /etc/nginx/fastcgi.conf 2>/dev/null || true
	$(QUIET)$(RM) /etc/nginx/fastcgi_params 2>/dev/null || true
	$(QUIET)$(RM) /etc/nginx/proxy_params 2>/dev/null || true
	$(QUIET)$(RM) /etc/nginx/snippets/pocket_ssl.conf 2>/dev/null || true
	$(QUIET)$(RM) /etc/nginx/snippets/fastcgi-php.conf 2>/dev/null || true
	$(QUIET)$(RM) /etc/nginx/nginx.conf 2>/dev/null || true
	$(QUIET)$(RM) /etc/nginx/sites-available/PiAP 2>/dev/null || true
	$(QUIET)unlink /etc/nginx/sites-enabled/PiAP 2>/dev/null || true
	$(QUITE)$(WAIT)
	$(QUIET)$(ECHO) "$@: Done."

configure-PiAP-keyring: install-optroot /etc/ssl/PiAPCA/crl /etc/ssl/PiAPCA/certs /etc/ssl/PiAPCA/private must_be_root
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/ssl/openssl.cnf /etc/ssl/PiAP_keyring.cfg
	$(QUIET)if [[ -z $$(grep -E "[0-9]+" /etc/ssl/PiAPCA/serial 2>/dev/null) ]] ; then $(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/etc/ssl/PiAPCA/serial /etc/ssl/PiAPCA/serial ; fi
	$(QUIET)touch -am /etc/ssl/PiAPCA/index.txt 2>/dev/null || true
	$(QUITE)$(CHOWN) $(FILE_OWN) /etc/ssl/PiAPCA/index.txt || true
	$(QUIET)$(ECHO) "$@: Done."

/etc/ssl/PiAPCA: /etc/ssl
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_PUB_DIR_OPTS) /etc/ssl/PiAPCA 2>/dev/null || true

/etc/ssl/PiAPCA/private: /etc/ssl/PiAPCA/
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /etc/ssl/PiAPCA/private 2>/dev/null || true

/etc/ssl/PiAPCA/crl: /etc/ssl/PiAPCA/
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /etc/ssl/PiAPCA/crl 2>/dev/null || true

/etc/ssl/PiAPCA/certs: /etc/ssl/PiAPCA/
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /etc/ssl/PiAPCA/certs 2>/dev/null || true

remove-PiAP-keyring: must_be_root
	$(QUIET)$(RM) /etc/ssl/PiAP_keyring.cfg 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

purge-PiAP-keyring: remove-PiAP-keyring must_be_root
	$(QUIET)$(RM) /etc/ssl/PiAPCA/index.txt || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/index.txt.old || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/serial || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/serial.old || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/certs/PiAP_SSL.pem || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/private/PiAP_SSL.csr || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/private/PiAP_SSL.key || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/private/PiAP_CA.csr || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/private/PiAP_CA.key || true
	$(QUIET)$(RM) /etc/ssl/PiAPCA/PiAP_CA.pem || true
	$(QUIET)$(RMDIR) /etc/ssl/PiAPCA/crl 2>/dev/null || true
	$(QUIET)$(RMDIR) /etc/ssl/PiAPCA/certs 2>/dev/null || true
	$(QUIET)$(RMDIR) /etc/ssl/PiAPCA/private 2>/dev/null || true
	$(QUIET)$(RMDIR) /etc/ssl/PiAPCA/ 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

configure-PiAP-sudoers: /etc/ must_be_root
	$(QUIET)if [[ ( -n $$( grep -F "PiAP" /etc/sudoers ) ) ]] ; then $(INSTALL) $(INST_ROOT_OWN) $(INST_FILE_OPS) ./PiAP/etc/sudoers.failsafe /etc/sudoers || exit 2 ; fi
	$(QUIET)if [[ ( -n $$( grep -F "PIAPS" /etc/sudoers ) ) ]] ; then $(INSTALL) $(INST_ROOT_OWN) $(INST_FILE_OPS) ./PiAP/etc/sudoers.failsafe /etc/sudoers || exit 2 ; fi
	$(QUIET)if [[ ( -z $$( grep -F "#includedir /etc/sudoers.d" /etc/sudoers ) ) ]] ; then echo "#includedir /etc/sudoers.d" | tee -a /etc/sudoers || exit 2 ; fi
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_FILE_OPTS) ./PiAP/etc/sudoers /etc/sudoers.d/001_PiAP || exit 2
	$(QUIET)$(ECHO) "$@: Done."

remove-PiAP-sudoers: must_be_root
	$(QUIET)$(RM) /etc/sudoers.d/001_PiAP 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

configure-PiAP-dnsmasq: install-optroot /etc/ must_be_root
	$(QUIET)$(INSTALL) $(INST_DNS_OWN) $(INST_WEB_OPTS) ./PiAP/etc/dnsmasq.conf /etc/dnsmasq.conf
	$(QUIET)$(INSTALL) $(INST_DNS_OWN) $(INST_WEB_OPTS) ./PiAP/etc/dnsmasq.d/dnsmasq.PiAP.conf /etc/dnsmasq.d/dnsmasq.PiAP.conf
	$(QUIET)$(ECHO) "$@: Done."

remove-PiAP-dnsmasq: must_be_root
	$(QUIET)$(RM) /etc/dnsmasq.d/dnsmasq.PiAP.conf 2>/dev/null || true
	$(QUIET)$(RM) /etc/dnsmasq.conf 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

configure-PiAP-hostapd: install-optroot /etc/hostapd must_be_root
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_OPTS) ./PiAP/etc/hostapd/hostapd.conf.backup /etc/hostapd/hostapd.conf.backup
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_OPTS) ./PiAP/etc/hostapd/hostapd.conf.failsafe /etc/hostapd/hostapd.conf.failsafe
	$(QUIET)$(ECHO) "$@: Done."

remove-PiAP-hostapd: must_be_root
	$(QUIET)$(RM) /etc/hostapd/hostapd.conf.backup 2>/dev/null || true
	$(QUIET)$(RM) /etc/hostapd/hostapd.conf.failsafe 2>/dev/null || true
	$(QUIET)$(RM) /etc/hostapd/hostapd.conf.bad 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

configure-PiAP-interfaces: /etc/network must_be_root
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_WEB_OPTS) ./PiAP/etc/network/interfaces /etc/network/interfaces
	$(QUIET)$(INSTALL) $(INST_ROOT_OWN) $(INST_FILE_OPTS) ./PiAP/etc/cron.hourly/clear_zeroconf_ip.sh /etc/cron.hourly/clear_zeroconf_ip.sh
	$(QUIET)$(ECHO) "$@: Done."

remove-PiAP-interfaces: must_be_root
	$(QUIET)$(RM) /etc/network/interfaces 2>/dev/null || true
	$(QUIET)$(RM) /etc/cron.hourly/clear_zeroconf_ip.sh 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

install-webroot: install-dsauth configure-httpd
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile install
	$(QUIET)$(ECHO) "$@: Done."

uninstall-webroot: remove-httpd uninstall-wpa-actions
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile uninstall
	$(QUIET)$(ECHO) "$@: Done."

uninstall: uninstall-optroot uninstall-dsauth remove-PiAP-sudoers remove-PiAP-dnsmasq uninstall-pifi
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile uninstall
	$(QUITE)$(WAIT)
	$(QUIET)$(ECHO) "$@: Done."

purge: clean uninstall remove-PiAP-keyring
	$(QUIET)deluser --system pocket 2>/dev/null || true
	$(QUIET)deluser --system pocket-www 2>/dev/null || true
	$(QUIET)deluser --system pocket-dns 2>/dev/null || true
	$(QUIET)deluser --system pocket-bot 2>/dev/null || true
	$(QUIET)deluser --system pocket-admin 2>/dev/null || true
	$(QUIET)delgroup --system pocket 2>/dev/null || true
	$(QUIET)delgroup --system --only-if-empty pocket-www 2>/dev/null || true
	$(QUIET)delgroup --system --only-if-empty pocket-dns 2>/dev/null || true
	$(QUIET)delgroup --system --only-if-empty pocket-bot 2>/dev/null || true
	$(QUIET)delgroup --system --only-if-empty pocket-admin 2>/dev/null || true
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile purge
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile purge
	$(QUIET)$(ECHO) "$@: Done."

test: cleanup
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile test || true
	$(QUIET)$(CP) ./units/PiAP-python-tools/.coverage ./.coverage || true
	$(QUIET)$(CP) ./units/PiAP-python-tools/.coverage.xml ./.coverage.xml 2>/dev/null || true
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile test
	$(QUIET)$(ECHO) "$@: Done."

test-tox: cleanup test
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile test-tox
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile test
	$(QUIET)$(ECHO) "$@: Done."

cleanup:
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile cleanup 2>/dev/null || true
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile cleanup 2>/dev/null || true
	$(QUIET)rm -f tests/*.pyc 2>/dev/null || true
	$(QUIET)rm -Rf tests/__pycache__ 2>/dev/null || true
	$(QUIET)rm -f PiAP/*.pyc 2>/dev/null || true
	$(QUIET)rm -f PiAP/*/*.pyc 2>/dev/null || true
	$(QUIET)rm -f PiAP/*/*~ 2>/dev/null || true
	$(QUIET)rm -f PiAP/*/*/*.pyc 2>/dev/null || true
	$(QUIET)rm -f PiAP/*/*/*~ 2>/dev/null || true
	$(QUIET)rm -Rf PiAP/__pycache__ 2>/dev/null || true
	$(QUIET)rm -Rf PiAP/*/__pycache__ 2>/dev/null || true
	$(QUIET)rm -f PiAP/*~ 2>/dev/null || true
	$(QUIET)rm -f *.pyc 2>/dev/null || true
	$(QUIET)rm -f PiAP/*/*.pyc 2>/dev/null || true
	$(QUIET)rm -f PiAP/*/*~ 2>/dev/null || true
	$(QUIET)rm -f *.DS_Store 2>/dev/null || true
	$(QUIET)rm -f ./.coverage 2>/dev/null || true
	$(QUIET)rm -f ./.coverage.xml 2>/dev/null || true
	$(QUIET)coverage erase 2>/dev/null || true
	$(QUIET)rm -f PiAP/*.DS_Store 2>/dev/null || true
	$(QUIET)rm -f PiAP/*/*.DS_Store 2>/dev/null || true
	$(QUIET)rm -f ./*/*~ 2>/dev/null || true
	$(QUIET)rm -f ./*~ 2>/dev/null || true
	$(QUIET)rm -f ./.travis.yml~ 2>/dev/null || true
	$(QUIET)rm -Rf ./.tox/ 2>/dev/null || true
	$(QUIET)rm -f ./the_test_file.txt 2>/dev/null || true

clean: cleanup
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile clean 2>/dev/null || true
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile clean 2>/dev/null || true
	$(QUIET)$(MAKE) -s -C ./docs/ -f Makefile clean 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

must_be_root:
	$(QUIET)runner=`whoami` ; \
	if test $$runner != "root" ; then echo "You are not root." ; exit 1 ; fi

/etc/ssl/PiAPCA/%: ./PiAP/etc/ssl/PiAPCA/% /etc/ssl/PiAPCA/
	$(QUIET)$(ECHO) "Auto Rule Found For $@" ; $(WAIT) ;
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_PUB_DIR_OPTS) $@ 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

%:
	$(QUIET)$(ECHO) "No Rule Found For $@" ; $(WAIT) ;

