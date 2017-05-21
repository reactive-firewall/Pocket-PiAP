#!/usr/bin/env make -f

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


ifeq "$(ECHO)" ""
	ECHO=echo
endif

ifeq "$(LINK)" ""
	LINK=ln -sf
endif

ifeq "$(MAKE)" ""
	MAKE=make
endif

ifeq "$(WAIT)" ""
	WAIT=wait
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
	ifeq "$(INST_OPTS)" ""
		INST_OPTS=-m 750
	endif
	ifeq "$(INST_FILE_OPTS)" ""
		INST_FILE_OPS=-m 640
	endif
	ifeq "$(INST_DIR_OPTS)" ""
		INST_DIR_OPTS=-m 750 -d
	endif
endif

ifeq "$(LOG)" ""
	LOG=no
endif

ifeq "$(LOG)" "no"
	QUIET=@
endif

PHONY: must_be_root cleanup

build:
	$(QUIET)$(ECHO) "No need to build. Try make -f Makefile install"

init:
	$(QUIET)$(ECHO) "$@: Done."

install: install-dsauth install-optroot install-wpa-actions install-hostapd-actions install-optsbin install-optbin must_be_root
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile install
	$(QUITE)$(WAIT)
	$(QUIET)$(ECHO) "$@: Done."

install-optroot: ./PiAP must_be_root
	$(QUIET)adduser --system --disabled-password --home /opt/PiAP/ --shell /bin/bash --force-badname --no-create-home --group pocket 2>/dev/null || true
	$(QUIET)adduser --system --disabled-password --home /opt/PiAP/ --shell /bin/bash --force-badname --no-create-home --group pocket-admin 2>/dev/null || true
	$(QUIET)adduser --system --disabled-password --home /srv/PiAP/ --force-badname --no-create-home --group pocket-www 2>/dev/null || true
	$(QUIET)adduser --system --disabled-password --home /opt/PiAP/ --force-badname --no-create-home --group pocket-www 2>/dev/null || true
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/
	$(QUIET)$(ECHO) "$@: Done."

uninstall-optroot: /opt/PiAP/ uninstall-wpa-actions uninstall-hostapd-actions uninstall-optbin uninstall-optsbin must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/
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
	$(QUIET)$(ECHO) "$@: Done."

uninstall-optsbin: must_be_root
	$(QUIET)$(RMDIR) /opt/PiAP/sbin 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."
	
install-wpa-actions: install-optroot must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/wpa_actions
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/list_networks /opt/PiAP/wpa_actions/list_networks
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/wpa_actions/status /opt/PiAP/wpa_actions/status
	$(QUIET)$(ECHO) "$@: Done."

uninstall-wpa-actions: must_be_root
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/list_networks 2>/dev/null || true
	$(QUIET)$(RM) /opt/PiAP/wpa_actions/status 2>/dev/null || true
	$(QUIET)$(RMDIR) /opt/PiAP/wpa_actions 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

install-hostapd-actions: install-optroot must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_DIR_OPTS) /opt/PiAP/hostapd_actions
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/opt/PiAP/hostapd_actions/clients /opt/PiAP/hostapd_actions/clients
	$(QUIET)$(ECHO) "$@: Done."

uninstall-hostapd-actions: must_be_root
	$(QUIET)$(RM) /opt/PiAP/hostapd_actions/clients 2>/dev/null || true
	$(QUIET)$(RMDIR) /opt/PiAP/hostapd_actions 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

install-dsauth: install-optroot must_be_root
	$(QUIET)$(INSTALL) $(INST_OWN) $(INST_OPTS) ./PiAP/srv/dsauth.py /srv/PiAP/dsauth.py
	$(QUIET)$(ECHO) "$@: Done."

uninstall-dsauth: uninstall-webroot must_be_root
	$(QUIET)$(RM) /srv/PiAP/dsauth.py 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

uninstall: uninstall-optroot uninstall-dsauth
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile uninstall
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile uninstall
	$(QUITE)$(WAIT)
	$(QUIET)$(ECHO) "$@: Done."

install-webroot:
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile install
	$(QUIET)$(ECHO) "$@: Done."

uninstall-webroot:
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile uninstall
	$(QUIET)$(ECHO) "$@: Done."

purge: clean uninstall
	$(QUIET)deluser --system pocket 2>/dev/null || true
	$(QUIET)deluser --system pocket-www 2>/dev/null || true
	$(QUIET)deluser --system pocket-dns 2>/dev/null || true
	$(QUIET)deluser --system pocket-bot 2>/dev/null || true
	$(QUIET)deluser --system pocket-admin 2>/dev/null || true
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile purge
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile purge
	$(QUIET)$(ECHO) "$@: Done."

test: cleanup
	$(QUIET)$(MAKE) -C ./units/PiAP-python-tools/ -f Makefile test-tox
	$(QUIET)$(MAKE) -C ./units/PiAP-Webroot/ -f Makefile test
	$(QUIET)$(ECHO) "$@: Done."

test-tox: cleanup test
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
	$(QUIET)rm -f piaplib/*.DS_Store 2>/dev/null || true
	$(QUIET)rm -f piaplib/*/*.DS_Store 2>/dev/null || true
	$(QUIET)rm -f ./*/*~ 2>/dev/null || true
	$(QUIET)rm -f ./*~ 2>/dev/null || true
	$(QUIET)rm -f ./.travis.yml~ 2>/dev/null || true
	$(QUIET)rm -Rf ./.tox/ 2>/dev/null || true
	$(QUIET)rm -f ./the_test_file.txt 2>/dev/null || true

clean: cleanup
	$(QUIET)$(MAKE) -s -C ./docs/ -f Makefile clean 2>/dev/null || true
	$(QUIET)$(ECHO) "$@: Done."

must_be_root:
	$(QUIET)runner=`whoami` ; \
	if test $$runner != "root" ; then echo "You are not root." ; exit 1 ; fi

%:
	$(QUIET)$(ECHO) "No Rule Found For $@" ; $(WAIT) ;

