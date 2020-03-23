#! /bin/bash

CI="${CI:-false}"
LANG="${LANG:-en_US.UTF-8}"
LANGUAGE="${LANGUAGE:-${LANG}}"
LC_ALL="${LC_ALL:-${LANG:-en_US}}"
SHELL=$(command -v bash)

ROLL_BACK=0
WARN_VAR=0
PRE_PIAP_UMASK=$(umask)
umask 027

export PIAP_UI_BRANCH="${PIAP_UI_BRANCH:-stable}"

PIAP_USER=${PIAP_USER:-0}
PIAP_GROUP=${PIAP_GROUP:-0}
PIAP_LOG_NAME=${PIAP_LOG_NAME:-PiAP_update_log.log}
PIAP_LOG_PATH=${PIAP_LOG_PATH:-"/tmp/${PIAP_LOG_NAME:-PiAP_update_log.log}"}

function message() {
	local PIAP_MESSAGE="${@}"
	# echo ""
	echo "${PIAP_MESSAGE}" | tee -a "${PIAP_LOG_PATH}" 2>/dev/null || true ;
	return 0
}

function check_depends() {
	local THEDEPENDS=$"${1:-python3}"
	local DID_WORK=0
	local DOWN_RETRY=5
	local DOWN_COUNT=0
	if [[ ( $(dpkg --list | grep -E "^[i]{2}[[:space:]]+" | tr -s '\s' ' ' | cut -d \  -f 2 | grep -F -c "${THEDEPENDS}" ) -le 0 ) ]] ; then
		message "Installing new dependencies. [\"${THEDEPENDS}\"]"
		OLDMASK=$(umask)
		umask 0022
		while [[ ( $DOWN_COUNT -le $DOWN_RETRY ) ]] ; do
			DOWN_COUNT=$(($DOWN_COUNT+1)) ;
			if [[ ( "$DID_WORK" -gt 0 ) ]] ; then
				message "Retry ${DOWN_COUNT:-again}"
				{ sudo apt-get install --assume-yes --download-only "${THEDEPENDS}" 2>/dev/null && DID_WORK=0 ; } || true ;
			elif [[ ( $DOWN_COUNT -le 1 ) ]] ; then
				{ sudo apt-get install --assume-yes --download-only "${THEDEPENDS}" 2>/dev/null && DID_WORK=0 ; } || DID_WORK=1 ;
			fi
		done
		sudo apt-get install -y "${THEDEPENDS}" 2>/dev/null || DID_WORK=1 ;
		umask "$OLDMASK"
		message "DONE"
	else
		message "Found dependencies. [\"${THEDEPENDS}\"]"
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
		OLDMASK=$(umask)
		umask 0000
		ln -sf "${THEPATH}" "${THELINK}" 2>/dev/null || test -L "${THELINK}" || stat "${THELINK}" || DID_WORK=1 ;
		chown -h "${2:-${PIAP_USER}}:${3:-${PIAP_GROUP:-${PIAP_USER}}}" "${THELINK}" 2>/dev/null || true ;
		umask "$OLDMASK"
		message "DONE"
	fi
	return $DID_WORK
}

message "Date:"$(date)

if [[ ( -n $(command -v apt-get ) ) ]] ; then
	message "updating system to latest."
	sudo apt-get --assume-no update || ROLL_BACK=1 ;
	sudo apt-get --only-upgrade --assume-yes dist-upgrade || sudo apt-get --only-upgrade -f --assume-yes dist-upgrade || ROLL_BACK=1 ;
	sudo apt-get --assume-yes autoremove || true ;
else
	message "WARNING: enviroment seems wrong."
	message "WARNING: NOT updating system to latest."
fi ;

if [[ ( ${ROLL_BACK:-1} -gt 0 ) ]] ; then
	message "WARNING: enviroment failed to upgrade."
	message "WARNING: NOT updating system to latest."
	exit 2 ;
fi

for SOME_DEPENDS in build-essential make logrotate git gnupg2 nginx nginx-full dnsmasq hostapd python3 python3-pip ; do
	check_depends ${SOME_DEPENDS} || exit 2 ;
done ;

check_depends php-fpm && { check_depends php7.0-xsl || check_depends php-xsl ; } || check_depends php5-fpm || exit 2 ;
PIAP_PHP_V_STUB=$(php --version | grep -oE "^[PH]{3}\s+[7.0|7.1|7.2|7.3|7.4]{3}" 2>/dev/null | head -n 1);
PIAP_PHP_VERSION=$(echo "${PIAP_PHP_V_STUB:-5}" | grep -oE "\d+[.\d]*" | head -n 1);
export PIAP_PHP_VERSION ;
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
sudo rm -Rvf /var/opt/PiAP/backups/SSL_OLD/ 2>/dev/null || true ;
if [[ ( -e /var/opt/PiAP/backups/PiAP ) ]] ; then
	sudo mv -vf /var/opt/PiAP/backups/PiAP /var/opt/PiAP/backups/PiAP_OLD || true ;
fi
if [[ ( -e /var/opt/PiAP/backups/PiAP ) ]] ; then
	sudo mv -vf /var/opt/PiAP/backups/SSL /var/opt/PiAP/backups/SSL_OLD || true ;
fi
message "Backing up pre-upgrade version"
if [[ ( -d /srv/PiAP ) ]] ; then
	sudo cp -vfRpub /srv/PiAP /var/opt/PiAP/backups/PiAP || exit 3 ;
else
	message "Nothing to backup! No pre-upgrade version."
	check_path /srv/PiAP/ || exit 2 ;
fi
if [[ ( -d /etc/ssl ) ]] ; then
	sudo cp -vfRpub /etc/ssl /var/opt/PiAP/backups/SSL || exit 3 ;
else
	message "Nothing to backup! No pre-upgrade version."
	check_path /etc/ssl/ || exit 2 ;
fi
message "Backing up Complete"
message "Disabling web-server to prevent inconsistent state. All web sessions will be logged out."
sudo service nginx stop || true ;
sudo service nginx status || true ;
sudo service "php${PIAP_PHP_VERSION}-fpm" stop 2>/dev/null || sudo systemctl stop "php${PIAP_PHP_VERSION}-fpm" 2>/dev/null || true
sudo service "php${PIAP_PHP_VERSION}-fpm" status 2>/dev/null || sudo systemctl --no-pager --type=service status "php${PIAP_PHP_VERSION}-fpm" 2>/dev/null || true
message "Fetching upgrade files..."
# data
rm -vfR ./Pocket-PiAP 2>/dev/null || true
git clone -b ${PIAP_UI_BRANCH:-stable} https://github.com/reactive-firewall/Pocket-PiAP.git || true ;
cd ./Pocket-PiAP || ROLL_BACK=2 ;
message "Selecting branch ${PIAP_UI_BRANCH:-stable}"
git fetch "${CI_REMOTE:-origin}" "${CIRCLE_BRANCH:-${CIRCLE_SHA1:-stable}}" || git fetch --all || ROLL_BACK=2 ;
git pull || git pull --all || ROLL_BACK=2 ;
git checkout --force ${PIAP_UI_BRANCH:-stable} || ROLL_BACK=2 ;
git submodule init || true ;
git submodule update --remote --checkout || ROLL_BACK=2 ;
git config --local fetch.recursesubmodules true ;
git fetch || ROLL_BACK=2 ;
git pull || ROLL_BACK=2 ;
git checkout --force ${PIAP_UI_BRANCH:-stable} || ROLL_BACK=2 ;

if [[ ( ${ROLL_BACK:-2} -gt 0 ) ]] ; then
	message "Status: FAILED TO UPGRADE FROM REPO"
	message "THIS IS AN ERROR - UPDATE WILL FAIL!"
fi

# keys
GIT_GPG_CMD=$(git config --get gpg.program)
GIT_GPG_CMD=${GIT_GPG_CMD:-$(command -v gpg2)}
git config --local gpg.program "${GIT_GPG_CMD}"

if [[ ( $(${GIT_GPG_CMD} --gpgconf-test 2>/dev/null ; echo -n "$?" ) -eq 0 ) ]] ; then
	message "Enabled TRUST CHECK. [BETA TEST]"

	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_A.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n3\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key CF76FC3B8CD0B15F 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_B.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n3\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 2FDAFC993A61112D 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_C.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n3\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key F55A399B1FE18BCB 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_ABC.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n4\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key DE1F0294A79F5244 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_D.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n3\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 055521972A2DF921 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_E.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n3\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 7A4FC8AFC5FF91EE 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_F.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n3\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 1B38E552E4E90FDB 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_G.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n4\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 157F7C20C1B17EAF 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_H.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	if [[ ( ${ROLL_BACK:-2} -gt 0 ) ]] ; then
		message "FAILED TO import A1D551AADC439CC5"
		message "THIS IS AN ERROR - UPDATE WILL FAIL!"
	fi
	printf 'trust 1\n4\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key A1D551AADC439CC5 2>/dev/null || WARN_VAR=2 ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_I.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	if [[ ( ${ROLL_BACK:-2} -gt 0 ) ]] ; then
		message "FAILED TO import 71BEC57F7ACABE5F"
		message "THIS IS AN ERROR - UPDATE WILL FAIL!"
	fi
	printf 'trust 1\n4\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 71BEC57F7ACABE5F 2>/dev/null || WARN_VAR=2 ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_K.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	if [[ ( ${ROLL_BACK:-2} -gt 0 ) ]] ; then
		message "FAILED TO import 11D97E1BAD186C99"
		message "THIS IS AN ERROR - UPDATE WILL FAIL!"
	fi
	printf 'trust 1\n4\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 11D97E1BAD186C99 2>/dev/null || WARN_VAR=2 ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_J.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n4\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 8A90BD3AA562D23F 2>/dev/null || true ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Verification_HIJK.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || ROLL_BACK=2 ;
	if [[ ( ${ROLL_BACK:-2} -gt 0 ) ]] ; then
		message "FAILED TO import B040F898E240C2E2"
		message "THIS IS AN ERROR - UPDATE WILL FAIL!"
	fi
	printf 'trust 1\n4\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key B040F898E240C2E2 2>/dev/null || WARN_VAR=2 ; wait ;
	curl -fsSL --tlsv1.2 --header "Dnt: 1" --header "Accept: application/pgp-keys" --url "https://sites.google.com/site/piappki/Pocket_PiAP_Codesign_CA.asc?attredirects=0&d=1" 2>/dev/null 3>/dev/null | ${GIT_GPG_CMD} --import 2>/dev/null || true ;
	printf 'trust 1\n4\nsave\n' | ${GIT_GPG_CMD} --command-fd 0 --edit-key 6B54E81C992370B6 2>/dev/null || WARN_VAR=2 ; wait ;
	${GIT_GPG_CMD} --check-trustdb 2>/dev/null || WARN_VAR=2 ;

	# BUG WHERE ELIPTIC CURVE keys are unusable ?!?! wtf is this weak sauce ?

# to verify the above code is unmodified the signed version is
# commented (prefixed by "# " 'number-sign & space') below for
# verification:
# 

# will add after beta when changes are less often and thus less sensitive to differential analysis

	if [[ ( ${WARN_VAR:-2} -gt 0 ) ]] ; then
		message "FAILED TO VERIFY CODESIGN TRUST ANCHORS"
		message "[MISSING BETA KEY ISSUE] need to download keys A1D551AADC439CC5, 71BEC57F7ACABE5F, 11D97E1BAD186C99, 8A90BD3AA562D23F, B040F898E240C2E2 and the current beta key. Probably 3C6DFFB3AC3BE369... [FIX ME]"
		# FIX THIS
		message "[BETA] RE-DISABLED TRUST CHECK."
		message "[BETA]: Attempting upgrading..."
	fi
else
	ROLL_BACK=3 ;
	message "DISABLED TRUST CHECK. [BETA TEST]"
fi
sudo git show --show-signature | grep -F ": " | grep -F "Pocket PiAP Codesign CA" | grep -F "Good signature" || (sudo git show --show-signature | grep -F ": " | grep -F "Signature made" && sudo git show --show-signature | grep -F ": " | grep -F "Invalid public key algorithm" || true ) || ROLL_BACK=1 ;
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
	message "FAILED TO VERIFY A CODESIGN TRUST"
	message "[MISSING BETA KEY ISSUE] need to download keys A1D551AADC439CC5, 71BEC57F7ACABE5F, 11D97E1BAD186C99, 8A90BD3AA562D23F, B040F898E240C2E2 and the current beta key. Probably 3C6DFFB3AC3BE369... [FIX ME]"
#fi # temp roll back [CAUTION for BETA]
#	message "NOT Attempting upgrading..."
else
	head -n 40 ./PiAP/etc/PocketAP_Banner 2>/dev/null || true
	message "Attempting upgrading..."
	message "DO NOT INTERRUPT OR POWER OFF. [CAUTION for BETA]"

	# set LED flashing here

	tee -a "${PIAP_LOG_PATH}" < <( sudo make uninstall ; echo $? >/tmp/result.tmp ) 2>/dev/null ; wait ;
	[[ $( head -n 1 </tmp/result.tmp ) -le 0 ]] || ROLL_BACK=2 ; rm -f /tmp/result.tmp ; wait ;
	umask 0002
	tee -a "${PIAP_LOG_PATH}" < <( sudo make install ; echo $? >/tmp/result.tmp ) 2>/dev/null ; wait ;
	[[ $( head -n 1 </tmp/result.tmp ) -le 0 ]] || ROLL_BACK=2 ; rm -f /tmp/result.tmp ; wait ;
	umask 0027
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
	sudo cp -vfRpub /var/opt/PiAP/backups/SSL /etc/ssl || message "FATAL error: device will need SSL reset. You found a bug. [BUGS] [FIX ME]"
fi
message "Checking TLS Beta cert links."
if [[ ( $( openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null | grep -cF OK ) -le 0 ) ]] ; then
	message "Rebuilding cert links"
	# sudo unlink /etc/ssl/certs/ssl-cert-CA-nginx.pem || true
	sudo ln -sf /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/certs/ssl-cert-CA-nginx.pem || true
elif [[ ( $( openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null | grep -cF 'certificate has expired' ) -gt 0 ) ]] ; then
	message "Rebuilding cert links"
	# sudo unlink /etc/ssl/certs/ssl-cert-CA-nginx.pem || true
	sudo ln -sf /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/certs/ssl-cert-CA-nginx.pem || true
fi
message "Checking TLS Beta cert dates."
if [[ ( $( openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null | grep -F -c OK ) -le 0 ) ]] ; then
	message "Applying HOTFIX - TLS Cert rotation for Beta"
	sudo rm -vf /etc/ssl/PiAPCA/certs/PiAP_SSL.pem
	umask 0002
	tee -a "${PIAP_LOG_PATH}" < <( sudo make /etc/ssl/PiAPCA/certs/PiAP_SSL.pem ; echo $? >/tmp/result.tmp ) 2>/dev/null ; wait ;
	[[ $( head -n 1 </tmp/result.tmp ) -le 0 ]] || ROLL_BACK=2 ; rm -f /tmp/result.tmp ; wait ;
	message "DONE"
elif [[ ( $( openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null | grep -cF 'certificate has expired' ) -gt 0 ) ]] ; then
	message "Applying HOTFIX - TLS Cert rotation for Beta"
	sudo rm -vf /etc/ssl/PiAPCA/certs/PiAP_SSL.pem
	umask 0002
	tee -a "${PIAP_LOG_PATH}" < <( sudo make /etc/ssl/PiAPCA/certs/PiAP_SSL.pem ; echo $? >/tmp/result.tmp ) 2>/dev/null ; wait ;
	[[ $( head -n 1 </tmp/result.tmp ) -le 0 ]] || ROLL_BACK=2 ; rm -f /tmp/result.tmp ; wait ;
	message "DONE"
	message "Cert should be fine now."
	message "You will probably have a browser warning about the new certificate, the next time you visit the web interface."
	openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null || true ; wait ;
else
	message "SSL Cert seems fine."
fi
message "Checking TLS Beta CA cert dates."
if [[ ( $( openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null | grep -F -c OK ) -le 0 ) ]] ; then
	message "Applying HOTFIX - TLS CA Cert rotation for Beta"
	sudo rm -vf /etc/ssl/PiAPCA/PiAP_CA.pem
	sudo rm -vf /etc/ssl/PiAPCA/certs/PiAP_SSL.pem
	umask 0002
	tee -a "${PIAP_LOG_PATH}" < <( sudo make /etc/ssl/PiAPCA/PiAP_CA.pem ; echo $? >/tmp/result.tmp ) 2>/dev/null ; wait ;
	[[ $( head -n 1 </tmp/result.tmp ) -le 0 ]] || ROLL_BACK=2 ; rm -f /tmp/result.tmp ; wait ;
	tee -a "${PIAP_LOG_PATH}" < <( sudo make /etc/ssl/PiAPCA/certs/PiAP_SSL.pem ; echo $? >/tmp/result.tmp ) 2>/dev/null ; wait ;
	[[ $( head -n 1 </tmp/result.tmp ) -le 0 ]] || ROLL_BACK=2 ; rm -f /tmp/result.tmp ; wait ;
	message "DONE"
elif [[ ( $( openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null | grep -F -c 'certificate has expired' ) -gt 0 ) ]] ; then
	message "Applying HOTFIX - TLS CA Cert rotation for Beta"
	sudo rm -vf /etc/ssl/PiAPCA/PiAP_CA.pem
	sudo rm -vf /etc/ssl/PiAPCA/certs/PiAP_SSL.pem
	umask 0002
	tee -a "${PIAP_LOG_PATH}" < <( sudo make /etc/ssl/PiAPCA/PiAP_CA.pem ; echo $? >/tmp/result.tmp ) 2>/dev/null ; wait ;
	[[ $( head -n 1 </tmp/result.tmp ) -le 0 ]] || ROLL_BACK=2 ; rm -f /tmp/result.tmp ; wait ;
	tee -a "${PIAP_LOG_PATH}" < <( sudo make /etc/ssl/PiAPCA/certs/PiAP_SSL.pem ; echo $? >/tmp/result.tmp ) 2>/dev/null ; wait ;
	[[ $( head -n 1 </tmp/result.tmp ) -le 0 ]] || ROLL_BACK=2 ; rm -f /tmp/result.tmp ; wait ;
	message "DONE"
	message "Cert should be fine now."
	message "You will probably have a browser warning about the new certificate, the next time you visit the web interface."
	openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null || true ; wait ;
else
	message "CA Cert seems fine."
fi
umask 0027
message "Checking SSH dates."
if [[ ( $( find /etc/ssh -iname "*.pub" -ctime +30 -print0 2>/dev/null | xargs -0 -L1 -I{} echo "{}" | wc -l ) -ge 1 ) ]] ; then
	message "Applying HOTFIX - SSH key rotation for Beta"
	find /etc/ssh -iname "*.pub" -ctime +30 -print0 2>/dev/null | xargs -0 -L1 rm -vf ; wait ;
	sudo ssh-keygen -A ; wait ;
	message "DONE"
	message "AFTER LOGGING OUT of this ssh session YOU MUST REMOVE TRUST OF THE OLD KEY by running: ssh-keygen -R ${HOSTNAME:-pocket.piap.local}"
	message "The NEW keys you will need to verify are:"
	find /etc/ssh -iname "*.pub" -print0 2>/dev/null | xargs -0 -L1 sudo ssh-keygen -l -v -f | tee -a "${PIAP_LOG_PATH}" 2>/dev/null;
else
	message "SSH keys seem fine."
fi

if [[ ( 0 -ge ${ROLL_BACK:-3} ) ]] ; then
	message "Upgrade seems fine ... SKIPPING BACKUP RESTORE!"
fi

message "Restarting web-server."
sudo service "php${PIAP_PHP_VERSION}-fpm" start 2>/dev/null || true ;
if [[ ${CI} ]] ; then
	mv -vf /etc/nginx/sites-available/PiAP /etc/nginx/sites-available/PiAP.tmp 2>/dev/null || ROLL_BACK=2 ;
	sed -E -e 's/10.0.40.1://g' /etc/nginx/sites-available/PiAP.tmp 2>/dev/null | tee /etc/nginx/sites-available/PiAP || ROLL_BACK=3 ;
	rm -vf /etc/nginx/sites-available/PiAP.tmp 2>/dev/null || ROLL_BACK=2 ;
fi
sudo service nginx start || sudo rm -vf /etc/nginx/sites-enabled/default 2>/dev/null || true && sudo service nginx start || ROLL_BACK=1 ;
sudo service nginx status || sudo systemctl --no-pager status nginx.service || true ;
sudo service "php${PIAP_PHP_VERSION}-fpm" start 2>/dev/null || sudo service "php${PIAP_PHP_VERSION}-fpm" restart 2>/dev/null || sudo systemctl start "php${PIAP_PHP_VERSION}-fpm.service" 2>/dev/null || sudo systemctl restart "php${PIAP_PHP_VERSION}-fpm.service" 2>/dev/null || true ;
sudo service "php${PIAP_PHP_VERSION}-fpm" status 2>/dev/null || sudo systemctl --no-pager status "php${PIAP_PHP_VERSION}-fpm.service" 2>/dev/null || true ;
if [[ ( ${ROLL_BACK:-1} -eq 1 ) ]] ; then
	message "Restarting web-server FAILED!"
else
	message "DONE"
fi
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
SSH_PORT=$(echo ${SSH_CONNECTION} | cut -d\  -f 4 )
SSH_SERVER=$(echo ${SSH_CONNECTION} | cut -d\  -f 3 )
( test -x /usr/bin/raspi-config 2>/dev/null && sudo /opt/PiAP/bin/set_LED_status_Agro.bash 2>/dev/null ) || true
message "Status: Upgrade failed."
message "Please report this issue at https://github.com/reactive-firewall/Pocket-PiAP/issues"
message "[BETA] Please include the contents of this log \"${PIAP_LOG_PATH}\""
if [[ $CI ]] ; then
	message "[BETA] CI SERVICES"
	sudo service --status-all 2>/dev/null || sudo systemctl --no-pager --type=service status 2>/dev/null || true
	message "[BETA] Environment details:"
	env
	pwd
	bash --version
	message "[BETA] ROLL_BACK=${ROLL_BACK}"
	message "[BETA] WARN_VAR=${WARN_VAR}"
	message "[BETA] PIAP_UI_BRANCH=${PIAP_UI_BRANCH}"
	message "[BETA] PIAP_USER=${PIAP_USER}"
	message "[BETA] PIAP_GROUP=${PIAP_GROUP}"
	message "[BETA] PIAP_LOG_NAME=${PIAP_LOG_NAME}"
	message "[BETA] PIAP_LOG_PATH=${PIAP_LOG_PATH}"
	message "[BETA] GIT_GPG_CMD=${GIT_GPG_CMD}"
	${GIT_GPG_CMD} --list-sigs
	sudo git show --show-signature | grep -F ": " || true
	message "[BETA] GIT ENV"
	git config --list
	message "[BETA] PYTHON ENV"
	python3 --version
	python3 -m piaplib.pocket book version --all || true
	message "[BETA] WEB ENV"
	php --version
	head -n 4000 /etc/nginx/sites-available/PiAP || message "Missing /etc/nginx/sites-available/PiAP"
	head -n 4000 /etc/nginx/sites-available/default || message "Missing /etc/nginx/sites-available/default"
	sudo nginx -t -c /etc/nginx/nginx.conf || true
	message "[BETA] PHP-FPM paths:"
	( sudo ls -1 /var/run/ 2>/dev/null | grep -F "php" 2>/dev/null ) || true
	sudo ls -1 /var/run/php/ 2>/dev/null || true
	message "[BETA] PHP config uses:"
	find /etc/ -ipath "*/php*" -a -iname "*.conf*" -print0 2>/dev/null | xargs -0 -L1 -I{} sudo grep -F "listen" {} | grep -oE "^\s*listen\s*=\s*.*" | cut -d = -f 2- || true
fi
echo "[BETA] To copy logs localy without logging out you can open another Terminal and run:"
echo "     scp -2 -P ${SSH_PORT:-22} -r ${LOGNAME:-youruser}@${SSH_SERVER:-$HOSTNAME}:${PIAP_LOG_PATH} ~/Desktop/PiAP_BUG_Report_logs.log"
else
(test -x /usr/bin/raspi-config 2>/dev/null && sudo /opt/PiAP/bin/set_LED_status_Ready.bash ) || true
message "Status: Upgrade seemed to work. (check by logging in to the Web interface)"
fi
message "--------------------[LOG]----------------------"
head -n 9999999 "${PIAP_LOG_PATH}" || true ; wait ;

message "[DONE] SCRIPT IS NOW DONE. SAFE TO MOVE TO NEXT STEP"
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
message "[NEXT] Verify backups were restored. [This is not a sure thing]"
message "[NEXT] copy logs for bug report."
echo "[BETA] To copy logs localy without logging out you can open another Terminal and run:"
echo "     scp -2 -P ${SSH_PORT:-22} -r ${LOGNAME:-youruser}@${SSH_SERVER:-$HOSTNAME}:${PIAP_LOG_PATH} ~/Desktop/PiAP_BUG_Report_logs.log"
message "[NEXT] submit bug report."
else
message "[NEXT] Restart Pocket to complete the upgrades."
fi

# clean up env
umask "$PRE_PIAP_UMASK"
sudo -k
exit ${ROLL_BACK:-3} ;


