#! /bin/bash

CI="${CI:-false}"
ROLL_BACK=0

WARN_VAR=0

umask 027

export PIAP_UI_BRANCH="${PIAP_UI_BRANCH:-stable}"

PIAP_USER=${PIAP_USER:-0}
PIAP_GROUP=${PIAP_GROUP:-0}
PIAP_LOG_NAME=${PIAP_LOG_NAME:-PiAP_update_log.log}
PIAP_LOG_PATH=${PIAP_LOG_PATH:-"/tmp/${PIAP_LOG_NAME:-PiAP_update_log.log}"}

function message() {
	local PIAP_MESSAGE="${@}"
	echo ""
	echo "${PIAP_MESSAGE}" | tee -a "${PIAP_LOG_PATH}" 2>/dev/null
	echo ""
	return 0
}

function check_depends() {
	local THEDEPENDS=$"${1:-python3}"
	local DID_WORK=0
if [[ ( $(dpkg --list | grep -E "^[i]{2}[[:space:]]+" | tr -s '\s' ' ' | cut -d \  -f 2 | grep -F -c "${THEDEPENDS}" ) -le 0 ) ]] ; then
		message "Installing new dependencies. [\"${THEDEPENDS}\"]"
		sudo apt-get install -y "${THEDEPENDS}" 2>/dev/null || DID_WORK=1 ;
		message "DONE"
	fi
	return $DID_WORK
}

function check_path() {
	local THEPATH=$"${1:-/}"
	local DID_WORK=0
	if [[ ( -d "${THEPATH}" ) ]] ; then
		message "Found [\"${THEPATH}\"]"
	else
		message "Ensuring paths [\"${THEPATH}\"]"
		OLDMASK=$(umask)
		umask 0022
		mkdir -p "${THEPATH}" 2>/dev/null || DID_WORK=1 ;
		chown "${2:-${PIAP_USER}}:${3:-${PIAP_GROUP:-${PIAP_USER}}}" "${THEPATH}" 2>/dev/null || DID_WORK=1 ;
		umask "$OLDMASK"
		message "DONE"
	fi
	return $DID_WORK
}

function check_link() {
	local THEPATH=$"${1:-/}"
	local THELINK=$"${2:-/}"
	local DID_WORK=0
	if [[ ( -L "${THELINK}" ) ]] ; then
		message "Found [\"${THELINK}\"]"
	else
		check_path "${THEPATH}"
		message "Ensuring Links [\"${THEPATH}\"]"
		ln -sf "${THEPATH}" "${THELINK}" 2>/dev/null || test -L "${THELINK}" || stat "${THELINK}" || DID_WORK=1 ;
		chown -h "${2:-${PIAP_USER}}:${3:-${PIAP_GROUP:-${PIAP_USER}}}" "${THELINK}" 2>/dev/null || true ;
		message "DONE"
	fi
	return $DID_WORK
}

message "Date:"$(date)

if [[ ( -n $(which apt-get ) ) ]] ; then
	message "updating system to latest."
	sudo apt-get --assume-no update || ROLL_BACK=1 ;
	sudo apt-key update || true ;
	sudo apt-get --only-upgrade --assume-yes dist-upgrade || sudo apt-get --only-upgrade -f --assume-yes dist-upgrade || ROLL_BACK=1 ;
	sudo apt-get --assume-yes autoremove || true ;
	sudo apt-key update || true ;
else
	message "WARNING: enviroment seems wrong."
	message "WARNING: NOT updating system to latest."
fi ;

if [[ ( ${ROLL_BACK:-1} -gt 0 ) ]] ; then
	message "WARNING: enviroment failed to upgrade."
	message "WARNING: NOT updating system to latest."
	exit 2 ;
fi

cd /tmp ;
check_path /var/ || exit 2 ;
check_path /srv/ || exit 2 ;
check_path /opt/ || exit 2 ;
check_link /var/opt/ /opt/ || check_link /var/opt/PiAP/ /opt/PiAP/ || exit 2 ;
sudo rm -Rvf /var/opt/PiAP/backups/PiAP_OLD/ 2>/dev/null || true ;
check_path /var/opt/PiAP/ || exit 2 ;
check_path /var/opt/PiAP/backups/ || exit 2 ;
sudo chown ${PIAP_USER}:${PIAP_GROUP} /var/opt/PiAP/backups/ || true ;
sudo chown 750 /var/opt/PiAP/backups/ || true ;
sudo chown ${PIAP_USER}:${PIAP_GROUP} /var/opt/PiAP/ || true ;
sudo chown 755 /var/opt/PiAP/ || true ;
message "Making space for new backup up pre-upgrade version"
sudo rm -Rvf /var/opt/PiAP/backups/PiAP_OLD/ 2>/dev/null || true ;
if [[ ( -e /var/opt/PiAP/backups/PiAP ) ]] ; then
	sudo mv -vf /var/opt/PiAP/backups/PiAP /var/opt/PiAP/backups/PiAP_OLD || true ;
fi
message "Backing up pre-upgrade version"
if [[ ( -e /srv/PiAP ) ]] ; then
	sudo cp -vfRpub /srv/PiAP /var/opt/PiAP/backups/PiAP || exit 3 ;
else
	message "Nothing to backup! No pre-upgrade version."
	check_path /srv/PiAP/ || exit 2 ;
fi
message "Backing up Complete"
message "Disabling web-server to prevent inconsistent state. All sessions will be logged out."
sudo service nginx stop || true ;
sudo service php5-fpm stop 2>/dev/null || true ;
sudo service php7.0-fpm stop 2>/dev/null || true ;
message "Fetching upgrade files..."
# data
git clone -b ${PIAP_UI_BRANCH:-stable} https://github.com/reactive-firewall/Pocket-PiAP.git || true ;
cd ./Pocket-PiAP || ROLL_BACK=2 ;
message "Selecting branch ${PIAP_UI_BRANCH:-stable}"
git fetch || ROLL_BACK=2 ;
git pull || ROLL_BACK=2 ;
git checkout --force ${PIAP_UI_BRANCH:-stable} || ROLL_BACK=2 ;
git submodule init || ROLL_BACK=2 ;
git submodule update --remote --checkout || ROLL_BACK=2 ;
git config --local fetch.recursesubmodules true
git fetch || ROLL_BACK=2 ;
git pull || ROLL_BACK=2 ;
git checkout --force ${PIAP_UI_BRANCH:-stable} || ROLL_BACK=2 ;
# keys
GIT_GPG_CMD=$(git config --get gpg.program)
GIT_GPG_CMD=${GIT_GPG_CMD:-$(which gpg2)}
git config --local gpg.program ${GIT_GPG_CMD}
if [[ ( $(${GIT_GPG_CMD} --gpgconf-test 2>/dev/null ; echo -n "$?" ) -eq 0 ) ]] ; then
	message "Enabled TRUST CHECK. [BETA TEST] [FIXME]"

	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_A.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n3\nsave\n' | gpg2 --command-fd 0 --edit-key CF76FC3B8CD0B15F 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_B.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n3\nsave\n' | gpg2 --command-fd 0 --edit-key 2FDAFC993A61112D 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_C.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	printf 'trust 1\n4\nsave\n' | gpg2 --command-fd 0 --edit-key F55A399B1FE18BCB 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_ABC.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	printf 'trust 1\n4\nsave\n' | gpg2 --command-fd 0 --edit-key DE1F0294A79F5244 2>/dev/null || WARN_VAR=2 ; wait ;
	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_D.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	printf 'trust 1\n4\nsave\n' | gpg2 --command-fd 0 --edit-key 055521972A2DF921 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_E.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	printf 'trust 1\n4\nsave\n' | gpg2 --command-fd 0 --edit-key 7A4FC8AFC5FF91EE 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_F.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	printf 'trust 1\n4\nsave\n' | gpg2 --command-fd 0 --edit-key 1B38E552E4E90FDB 2>/dev/null || WARN_VAR=2 ; wait ;
	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_G.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	printf 'trust 1\n4\nsave\n' | gpg2 --command-fd 0 --edit-key 157F7C20C1B17EAF 2>/dev/null || WARN_VAR=2 ; wait ;
	curl -fsSL --tlsv1.2 --url "https://sites.google.com/site/piappki/Pocket_PiAP_Codesign_CA.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n4\nsave\n' | gpg2 --command-fd 0 --edit-key 87F06F1425B180C7 2>/dev/null || WARN_VAR=2 ; wait ;
	${GIT_GPG_CMD} --check-trustdb 2>/dev/null || ROLL_BACK=2 ;

	# BUG WHERE ELIPTIC CURVE keys are unusable ?!?! wtf is this weak sauce ?

# to verify the above code is unmodified the signed version is
# commented (prefixed by "# " 'number-sign & space') below for
# verification:
# 

# will add after beta when changes are less often and thus less sensitive to differential analysis

	if [[ ( ${WARN_VAR:-2} -gt 0 ) ]] ; then
		message "FAILED TO VERIFY CODESIGN TRUST ANCHORS"
		message "[MISSING BETA KEY ISSUE] need to download keys F55A399B1FE18BCB, 055521972A2DF921, 1B38E552E4E90FDB, 157F7C20C1B17EAF and the current beta key. Probably 87F06F1425B180C7... [FIX ME]"
		# FIX THIS
		message "BETA: Attempting upgrading..."
	fi
else
	ROLL_BACK=3 ;
	message "DISABLED TRUST CHECK. [BETA TEST]"
fi
sudo git show --show-signature | grep -F ": " | grep -F "Pocket PiAP Codesign CA" | grep -F "Good signature" || (sudo git show --show-signature | grep -F ": " | grep -F "Signature made" && sudo git show --show-signature | grep -F ": " | grep -F "Invalid public key algorithm" || true ) || ROLL_BACK=1 ;
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
	message "FAILED TO VERIFY A CODESIGN TRUST"
	message "[MISSING BETA KEY ISSUE] need to download keys F55A399B1FE18BCB, 055521972A2DF921, 1B38E552E4E90FDB, 157F7C20C1B17EAF and the current beta key. Probably 87F06F1425B180C7... [FIX ME]"
#fi # temp roll back [CAUTION for BETA]
#	message "NOT Attempting upgrading..."
else
message "Attempting upgrading..."
message "DO NOT INTERRUPT OR POWER OFF. [CAUTION for BETA]"

# set LED flashing here

( sudo make uninstall || ROLL_BACK=2 ) | tee -a "${PIAP_LOG_PATH}" 2>/dev/null
( sudo make install || ROLL_BACK=2 ) | tee -a "${PIAP_LOG_PATH}" 2>/dev/null
make clean
fi
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
	message "Upgrading FAILED. DO NOT INTERRUPT OR POWER OFF."
	message "Rolling back from backup. DO NOT INTERRUPT OR POWER OFF."
	message "... cleaning up mess from failed upgrade"
	sudo mv -vf /srv/PiAP /srv/PiAP_Failed || true ;
	sudo rm -vfR /srv/PiAP_Failed || true ;
	wait ;
	sudo cp -vfRpub /var/opt/PiAP/backups/PiAP /srv/PiAP || message "FATAL error: device will need full reset. Please report this issue at \"https://github.com/reactive-firewall/Pocket-PiAP/issues\" (include as much detail as possible) and might need to reconfigure your device (OS re-install + PiAP fresh install). You found a bug. [BUGS] [FIX ME]"
fi
message "Checking TLS Beta cert dates."
if [[ ( $( openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null | grep -F -c OK ) -le 0 ) ]] ; then
	message "Applying HOTFIX - TLS Cert rotation for Beta"
	sudo openssl genrsa -out /etc/ssl/PiAPCA/private/PiAP_SSL.key 4096 2>/dev/null ; wait ;
	sudo openssl req -new -outform PEM -out /root/ssl-cert-nginx.csr -key /etc/ssl/PiAPCA/private/PiAP_SSL.key -subj "/CN=pocket.PiAP.local/OU=PiAP.local/O=PiAP\ Network/" 2>/dev/null
	sudo openssl x509 -req -in /root/ssl-cert-nginx.csr -extfile /etc/ssl/PiAP_keyring.cfg -days 30 -extensions server_cert -CA /etc/ssl/PiAPCA/PiAP_CA.pem -CAkey /etc/ssl/PiAPCA/private/PiAP_CA.key -CAcreateserial | grep -F --after-context=400 -e $"-----BEGIN CERTIFICATE-----" | sudo tee /etc/ssl/certs/ssl-cert-nginx.pem ; wait ; sudo grep -F --after-context=400 -e $"-----BEGIN CERTIFICATE-----" /etc/ssl/certs/ssl-cert-CA-nginx.pem | sudo tee -a /etc/ssl/certs/ssl-cert-nginx.pem ; wait ; sudo service nginx restart ;
	message "DONE"
elif [[ ( $( openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null | fgrep -c 'certificate has expired' ) -gt 0 ) ]] ; then
	message "Applying HOTFIX - TLS Cert rotation for Beta"
	sudo openssl genrsa -out /etc/ssl/PiAPCA/private/PiAP_SSL.key 4096 2>/dev/null ; wait ;
	sudo openssl req -new -outform PEM -out /root/ssl-cert-nginx.csr -key /etc/ssl/PiAPCA/private/PiAP_SSL.key -subj "/CN=pocket.PiAP.local/OU=PiAP.local/O=Pocket\ PiAP/" 2>/dev/null
	sudo openssl x509 -req -in /root/ssl-cert-nginx.csr -extfile /etc/ssl/PiAP_keyring.cfg -days 30 -extensions server_cert -CA /etc/ssl/PiAPCA/PiAP_CA.pem -CAkey /etc/ssl/PiAPCA/private/PiAP_CA.key -CAcreateserial | grep -F --after-context=400 -e $"-----BEGIN CERTIFICATE-----" | sudo tee /etc/ssl/certs/ssl-cert-nginx.pem ; wait ; sudo grep -F --after-context=400 -e $"-----BEGIN CERTIFICATE-----" /etc/ssl/certs/ssl-cert-CA-nginx.pem | sudo tee -a /etc/ssl/certs/ssl-cert-nginx.pem ; wait ; sudo service nginx restart ;
	message "DONE"
	message "Cert should be fine now."
	message "You will probably have a browser warning about the new certificate, the next time you visit the web interface."
	openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null || true ; wait ;
else
	message "Cert seems fine."
fi
if [[ ( $( find /etc/ssh -iname *.pub -ctime +30 -print0 2>/dev/null | wc -l ) -ge 1 ) ]] ; then
	message "Applying HOTFIX - SSH key rotation for Beta"
	find /etc/ssh -iname *.pub -ctime +30 -print0 2>/dev/null | xargs -0 -L1 rm -vf ; wait ;
	sudo ssh-keygen -A ; wait ;
	message "DONE"
	message "AFTER LOGGING OUT of this ssh session YOU MUST REMOVE TRUST OF THE OLD KEY by running: ssh-keygen -R ${HOSTNAME:-pocket.piap.local}"
	message "The NEW keys you will need to verify are:"
	find /etc/ssh -iname *.pub -print0 2>/dev/null | xargs -0 -L1 sudo ssh-keygen -l -v -f | tee -a "${PIAP_LOG_PATH}" 2>/dev/null;
else
	message "SSH keys seem fine."
fi
message "Restarting web-server."
sudo service php5-fpm start 2>/dev/null || sudo service php7.0-fpm start 2>/dev/null || ROLL_BACK=1 ;
sudo service nginx start || sudo service nginx status || ROLL_BACK=1 ;
sudo service php5-fpm restart 2>/dev/null || sudo service php7.0-fpm restart 2>/dev/null || ROLL_BACK=1 ;
message "DONE"
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
SSH_PORT=$(echo ${SSH_CONNECTION} | cut -d\  -f 4 )
SSH_SERVER=$(echo ${SSH_CONNECTION} | cut -d\  -f 3 )
message "Status: Upgrade failed."
message "Please report this issue at https://github.com/reactive-firewall/Pocket-PiAP/issues"
message "[BETA] Please include the contents of this log \"${PIAP_LOG_PATH}\""
if [[ $CI ]] ; then
	message "[BETA] Environment details:"
	env
	pwd
	message "[BETA] ROLL_BACK=${ROLL_BACK}"
	message "[BETA] WARN_VAR=${WARN_VAR}"
	message "[BETA] PIAP_UI_BRANCH=${PIAP_UI_BRANCH}"
	message "[BETA] PIAP_USER=${PIAP_USER}"
	message "[BETA] PIAP_GROUP=${PIAP_GROUP}"
	message "[BETA] PIAP_LOG_NAME=${PIAP_LOG_NAME}"
	message "[BETA] PIAP_LOG_PATH=${PIAP_LOG_PATH}"
	message "[BETA] GIT_GPG_CMD=${GIT_GPG_CMD}"
	${GIT_GPG_CMD} --list-sigs
	sudo git show --show-signature | grep -F ": "
	git config --list
fi	
echo "[BETA] To copy logs localy without logging out you can open another Terminal and run:"
echo "     scp -2 -P ${SSH_PORT} -r ${LOGNAME:-youruser}@${SSH_SERVER:-$HOSTNAME}:${PIAP_LOG_PATH} ~/Desktop/PiAP_BUG_Report_logs.log"
else
message "Status: Upgrade seemed to work. (check by logging in to the Web interface)"
fi
message "--------------------[LOG]----------------------"
head -n 9999999 "${PIAP_LOG_PATH}" || true ; wait ;

message "[DONE] SCRIPT IS NOW DONE. SAFE TO MOVE TO NEXT STEP"
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
message "[NEXT] Verify backups were restored."
message "[NEXT] copy logs for bug report."
message "[NEXT] submit bug report."
else
message "[NEXT] Restart Pocket to complete the upgrades."
fi
sudo -k
exit ${ROLL_BACK:-3} ;


