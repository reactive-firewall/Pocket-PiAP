#! /bin/bash

ROLL_BACK=0

PIAP_UI_BRANCH="${PIAP_UI_BRANCH:-stable}"

PIAP_USER=${PIAP_USER:-0}
PIAP_GROUP=${PIAP_GROUP:-0}

function message() {
	local PIAP_MESSAGE="${@}"
	echo ""
	echo "${PIAP_MESSAGE}"
	echo ""
	return 0
}

message "updating system to latest."
sudo apt-get update || ROLL_BACK=1 ;
sudo apt-key update || ROLL_BACK=1 ;
sudo apt-get --only-upgrade --assume-yes dist-upgrade || ROLL_BACK=1 ;
sudo apt-get autoremove || ROLL_BACK=1 ;
cd /tmp ;
test -d /var/ || exit 2 ;
test -d /var/opt/ || mkdir -m 755 /var/opt/ && sudo chown 0:0 /var/opt/ || exit 2 ;
sudo rm -Rvf /var/opt/PiAP/backups/PiAP_OLD/ 2>/dev/null || true ;
test -d /var/opt/PiAP/ || mkdir -m 755 /var/opt/PiAP/ || exit 2 ;
test -d /var/opt/PiAP/backups/ || mkdir -m 755 /var/opt/PiAP/backups/ || exit 2 ;
sudo chown ${PIAP_USER}:${PIAP_GROUP} /var/opt/PiAP/backups/ || true ;
sudo chown 750 /var/opt/PiAP/backups/ || true ;
sudo chown ${PIAP_USER}:${PIAP_GROUP} /var/opt/PiAP/ || true ;
sudo chown 755 /var/opt/PiAP/ || true ;
message "Making space for new backup up pre-upgrade version"
sudo rm -Rvf /var/opt/PiAP/backups/PiAP_OLD/ 2>/dev/null || true ;
sudo mv -vf /var/opt/PiAP/backups/PiAP /var/opt/PiAP/backups/PiAP_OLD || true
message "Backing up pre-upgrade version"
sudo cp -vfRpub /srv/PiAP /var/opt/PiAP/backups/PiAP || exit 3 ;
message "disabling web-server to prevent inconsistent state. All sessions will be logged out."
sudo service nginx stop ;
sudo service php5-fpm stop ;
message "Fetching upgrade files..."
# data
git clone -b ${PIAP_UI_BRANCH:-stable} https://github.com/reactive-firewall/Pocket-PiAP.git || true ;
cd ./Pocket-PiAP || ROLL_BACK=2 ;
git fetch || ROLL_BACK=2 ;
git pull || ROLL_BACK=2 ;
git checkout --force ${PIAP_UI_BRANCH:-stable} || ROLL_BACK=2 ;
# keys
GIT_GPG_CMD=$(git config --get gpg.program)
GIT_GPG_CMD=${GIT_GPG_CMD:-$(which gpg2)}
if [[ ( $(${GIT_GPG_CMD} --gpgconf-test 2>/dev/null ; echo -n "$?" ) -eq 0 ) ]] ; then
	message "Enabled TRUST CHECK. [BETA TEST] [FIXME]"
	message "Use gpg command: \"${GIT_GPG_CMD}\""

	${GIT_GPG_CMD} --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0xCF76FC3B8CD0B15F 2>/dev/null || ROLL_BACK=2 ;
	${GIT_GPG_CMD} --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0x2FDAFC993A61112D 2>/dev/null || ROLL_BACK=2 ;
	${GIT_GPG_CMD} --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0xF55A399B1FE18BCB 2>/dev/null || ROLL_BACK=2 ;
	${GIT_GPG_CMD} --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0xB1E8C92F446CBB1B 2>/dev/null || ROLL_BACK=2 ;

# to verify the above code is unmodified the signed version is
# commented (prefixed by "# " 'number-sign & space') below for
# verification:
# 

# -----BEGIN PGP SIGNED MESSAGE-----
# Hash: SHA512
# 
# 	${GIT_GPG_CMD} --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0xCF76FC3B8CD0B15F 2>/dev/null || ROLL_BACK=2 ;
#  	${GIT_GPG_CMD} --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0x2FDAFC993A61112D 2>/dev/null || ROLL_BACK=2 ;
#  	${GIT_GPG_CMD} --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0xF55A399B1FE18BCB 2>/dev/null || ROLL_BACK=2 ;
#  	${GIT_GPG_CMD} --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0xB1E8C92F446CBB1B 2>/dev/null || ROLL_BACK=2 ;
# 
# -----BEGIN PGP SIGNATURE-----
# 
# iJ4EARMKAAYFAlktFAcACgkQsejJL0RsuxsaGgH/YFNSUC1FldZJmFkTN8FPXlHa
# 2GWdheW02Yi8h5x74kiMGQLbu1QRxWl2NSpRxq1XCCFNf1HLwV1e6ZwHsFORnAH/
# SbbnvRrFPMRIHGxE0YiZtTVkEWoXAQTlJ0zSQMC2zxDXENpVOZ9CtZXSlDMWWODy
# WEEPBHrmiEtnajuMqeYScw==
# =1ghI
# -----END PGP SIGNATURE-----
	
else
	ROLL_BACK=3 ;
	message "DISABLED TRUST CHECK. [BETA TEST]"
fi
git show --show-signature | fgrep gpg | fgrep "Pocket PiAP Codesign CA" | fgrep "Good signature" || ROLL_BACK=1 ;
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
	message "FAILED TO VERIFY A CODESIGN TRUST"
	message "[MISSING BETA KEY ISSUE] might need to download keys CF76FC3B8CD0B15F, 2FDAFC993A61112D, F55A399B1FE18BCB, and the current beta key. Probably B1E8C92F446CBB1B... [FIX ME]"
	message "NOT Attempting upgrading..."
else
message "Attempting upgrading..."
message "DO NOT INTERRUPT OR POWER OFF. [CAUTION for BETA]"
sudo make uninstall || ROLL_BACK=2 ;
sudo make install || ROLL_BACK=2 ;
make clean
fi
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
	message "Upgrading FAILED. DO NOT INTERRUPT OR POWER OFF."
	message "Rolling back from backup. DO NOT INTERRUPT OR POWER OFF."
	message "... cleaning up mess from failed upgrade"
	sudo mv -vf /srv/PiAP /srv/PiAP_Failed || true ;
	sudo rm -vfR /srv/PiAP_Failed || true ;
	wait ;
	sudo cp -vfRpub /var/opt/PiAP/backups/PiAP /srv/PiAP || message "FATAL error: device will need full reset. Please report this issue at \"https://github.com/reactive-firewall/PiAP-Webroot/issues\" (include as much detail as possible) and might need to reconfigure your device (OS re-install + PiAP fresh install). You found a bug. [BUGS] [FIX ME]"
fi
message "checking TLS Beta cert dates."
if [[ ( $( openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null | fgrep -c OK ) -le 0 ) ]] ; then
	message "Applying HOTFIX - TLS Cert rotation for Beta"
	sudo openssl x509 -req -in /root/ssl-cert-nginx.csr -extfile /etc/ssl/PiAP_keyring.cfg -days 30 -extensions usr_cert -CA /etc/ssl/PiAP_CA/PiAP_CA.pem -CAkey /etc/ssl/private/ssl-cert-CA-nginx.key -CAcreateserial | fgrep --after-context=400 -e $"-----BEGIN CERTIFICATE-----" | sudo tee /etc/ssl/certs/ssl-cert-nginx.pem ; wait ; sudo fgrep --after-context=400 -e $"-----BEGIN CERTIFICATE-----" /etc/ssl/certs/ssl-cert-CA-nginx.pem | sudo tee -a /etc/ssl/certs/ssl-cert-nginx.pem ; wait ; sudo service nginx restart ;
else
	message "Cert seems fine."
fi
if [[ ( $( find /etc/ssh -iname *.pub -ctime +30 -print0 2>/dev/null | wc -l ) -ge 1 ) ]] ; then
	message "Applying HOTFIX - SSH key rotation for Beta"
	find /etc/ssh -iname *.pub -ctime +30 -print0 2>/dev/null | xargs -0 -L1 rm -vf ; wait ;
	sudo ssh-keygen -A ; wait ;
	message "AFTER LOGGING OUT of this ssh session YOU MUST REMOVE TRUST OF THE OLD KEY by running: ssh-keygen -R ${HOSTNAME:-pocket.piap.local}"
	message "The NEW keys you will need to verify are:"
	find /etc/ssh -iname *.pub -print0 2>/dev/null | xargs -0 -L1 sudo ssh-keygen -l -v -f ;
else
	message "ssh keys seem fine."
fi
message "restarting web-server."
sudo service php5-fpm start || ROLL_BACK=1 ;
sudo service nginx start || ROLL_BACK=1 ;
sudo service php5-fpm restart || ROLL_BACK=1 ;
message "DONE"
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
message "Status: Upgrade failed."
message "Please report this issue at https://github.com/reactive-firewall/Pocket-PiAP/issues"
else
message "Status: Upgrade seemed to work."
fi
message "restart to complete"
sudo -k
exit ${ROLL_BACK:-3} ;


