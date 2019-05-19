#! /bin/bash

CI="${CI:-false}"
ROLL_BACK=0

WARN_VAR=0

umask 027

export PIAP_UI_BRANCH="${PIAP_UI_BRANCH:-stable}"

PIAP_USER=${PIAP_USER:-0}
PIAP_GROUP=${PIAP_GROUP:-0}
PIAP_LOG_NAME=${PIAP_LOG_NAME:-PiAP_doctor_log.log}
PIAP_LOG_PATH=${PIAP_LOG_PATH:-"/tmp/${PIAP_LOG_NAME:-PiAP_doctor_log.log}"}

function xwhich() {
	if [[ ( -x $(whereis which | head -n 1) ) ]] ; then
		return $(whereis which | head -n 1 )
	else
		return $(which which | head -n1 )
	fi
}

function confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

function message() {
	local PIAP_MESSAGE=$*
	# echo ""
	echo "${PIAP_MESSAGE}" | tee -a "${PIAP_LOG_PATH}" 2>/dev/null || true
	return 0
}

function check_depends() {
	local THEDEPENDS=$"${1:-python3}"
	local DID_WORK=0
	local DOWN_RETRY=5
	local DOWN_COUNT=0
	if [[ ( $(dpkg --list | grep -E "^[i]{2}[[:space:]]+" | tr -s '\s' ' ' | cut -d \  -f 2 | grep -F -c "${THEDEPENDS}" ) -le 0 ) ]] ; then
		message "Installing new dependencies. [\\"${THEDEPENDS}\\"]"
		OLDMASK=$(umask)
		umask 0022
		while [[ ( $DOWN_COUNT -le $DOWN_RETRY ) ]] ; do
			DOWN_COUNT=$((DOWN_COUNT+1)) ;
			if [[ $DID_WORK -gt 0 ]] ; then
				message "Retry ${DOWN_COUNT:-again}"
				( sudo apt-get install --assume-yes --download-only "${THEDEPENDS}" 2>/dev/null && DID_WORK=0 ) || true ;
			elif [[ ( $DOWN_COUNT -le 1 ) ]] ; then
				( sudo apt-get install --assume-yes --download-only "${THEDEPENDS}" 2>/dev/null && DID_WORK=0 ) || DID_WORK=1 ;
			fi
		done
		sudo apt-get install -y "${THEDEPENDS}" 2>/dev/null || DID_WORK=1 ;
		umask "$OLDMASK" ;
		message "DONE" ;
	else
		message "Found dependencies. [\\"${THEDEPENDS}\\"]" ;
	fi
	return $DID_WORK ;
}

function check_path() {
	local THEPATH=$"${1:-/}"
	local DID_WORK=0
	if [[ ( -d "${THEPATH}" ) ]] ; then
		message "Found [\"${THEPATH}\"]"
	else
		message "Ensuring paths [\\"${THEPATH}\\"]"
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
		check_path "${THEPATH}" ;
		message "Ensuring Links [\\"${THEPATH}\\"]" ;
		ln -sf "${THEPATH}" "${THELINK}" 2>/dev/null || test -L "${THELINK}" || stat "${THELINK}" || DID_WORK=1 ;
		chown -h "${2:-${PIAP_USER}}:${3:-${PIAP_GROUP:-${PIAP_USER}}}" "${THELINK}" 2>/dev/null || true ;
		message "DONE" ;
	fi
	return $DID_WORK ;
}

function check_backups() {
	local THESOURCE=$"${1:-/srv/PiAP}"
	local THE_STUB
	THE_STUB=$(dirname $"${1:-/srv/PiAP}")
	local THEDEST=/var/opt/PiAP/backups/"${THE_STUB}"
	local DID_WORK=1
	check_path /var/opt/PiAP/backups/ || DID_WORK=0 ;
	sudo chown "${2:-${PIAP_USER}}:${3:-${PIAP_GROUP:-${PIAP_USER}}}" /var/opt/PiAP/backups/ || true ;
	sudo chown 750 /var/opt/PiAP/backups/ || true ;
	sudo chown "${2:-${PIAP_USER}}:${3:-${PIAP_GROUP:-${PIAP_USER}}}" /var/opt/PiAP/ || true ;
	sudo chown 755 /var/opt/PiAP/ || true ;
	message "Making space for new backup up pre-upgrade version"
	( confirm "Clear space from old backups? [y/n]" && sudo rm -Rvf "${THEDEST}_OLD" 2>/dev/null ) || true ;
	if [[ ( -e "${THEDEST}" ) ]] ; then
		sudo mv -vf "${THEDEST}" "${THEDEST}_OLD" || true ;
	fi
	message "Backing up pre-upgrade version"
	if [[ ( -e /srv/PiAP ) ]] ; then
		sudo cp -vfRpub "${THESOURCE}" "${THEDEST}" || DID_WORK=0 ;
	else
		message "Nothing to backup! No pre-upgrade version." ;
		check_path "${THESOURCE}" || DID_WORK=0 ;
	fi
	message "Backing up Complete. [\\"${THESOURCE}\\"]" ;
	return $DID_WORK ;
}


message "Date:$(date)"

if [[ ( -n $(xwhich apt-get ) ) ]] ; then
	message "updating system to latest."
	sudo apt-get --assume-no update || ROLL_BACK=1 ;
	sudo apt-key update || true ;
	sudo apt-get --only-upgrade --assume-yes dist-upgrade || sudo apt-get --only-upgrade -f --assume-yes dist-upgrade || ROLL_BACK=1 ;
	message "about to remove stale packages"
	( confirm && sudo apt-get --purge --assume-yes autoremove ) || true ;
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


for SOME_DEPENDS in build-essential make logrotate git gnupg2 nginx nginx-full dnsmasq hostapd python3 python3-pip nmap clamav-freshclam ; do
	check_depends ${SOME_DEPENDS} || exit 2 ;
done ;

check_depends php-fpm && check_depends php7.0-xsl || check_depends php5-fpm || exit 2 ;

cd /tmp || exit 2 ;
check_path /var/ || exit 2 ;
check_path /srv/ || exit 2 ;
check_path /opt/ || exit 2 ;
check_link /var/opt/ /opt/ || check_link /var/opt/PiAP/ /opt/PiAP/ || exit 2 ;
check_path /var/opt/PiAP/ || exit 2 ;
check_path /var/opt/PiAP/backups/ || exit 2 ;
sudo chown "${PIAP_USER}":"${PIAP_GROUP}" /var/opt/PiAP/backups/ || true ;
sudo chown 750 /var/opt/PiAP/backups/ || true ;
sudo chown "${PIAP_USER}":"${PIAP_GROUP}" /var/opt/PiAP/ || true ;
sudo chown 755 /var/opt/PiAP/ || true ;

for SOME_SOURCE in /srv/PiAP /etc/ssl ; do
        check_backups "${SOME_SOURCE}" || exit 2 ;
done ;

message "Disabling services to prevent inconsistent state. All sessions will be logged out."
sudo service nginx stop || true ;
sudo service nginx status || true ;
sudo service php5-fpm stop 2>/dev/null || true ;
sudo service php7.0-fpm stop 2>/dev/null || true ;

message "Checking TLS Beta cert dates."
if [[ ( $( openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null | grep -cF OK ) -le 0 ) ]] ; then
	openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem | tee -a "${PIAP_LOG_PATH}" 2>/dev/null ;
	message "Recommend rebuilding cert links"
	echo "sudo unlink /etc/ssl/certs/ssl-cert-CA-nginx.pem || true"
	echo "sudo ln -sf /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/certs/ssl-cert-CA-nginx.pem || echo FAILED"
elif [[ ( $( openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null | grep -cF 'certificate has expired' ) -gt 0 ) ]] ; then
	openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem | tee -a "${PIAP_LOG_PATH}" 2>/dev/null ;
	message "Certificate has expired. Recommend rebuilding cert links"
	echo "sudo unlink /etc/ssl/certs/ssl-cert-nginx.pem || true"
	echo "# NOT SUPPORTED YET."
fi
if [[ ( $( openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null | grep -F -c OK ) -le 0 ) ]] ; then
	openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem | tee -a "${PIAP_LOG_PATH}" 2>/dev/null ;
	message "Certificate is invalid. Recommend rebuilding cert links"
	echo "sudo rm -vf /etc/ssl/PiAPCA/certs/PiAP_SSL.pem || true"
	echo "# NOT SUPPORTED YET."
	message "DONE"
elif [[ ( $( openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem 2>/dev/null | grep -cF 'certificate has expired' ) -gt 0 ) ]] ; then
	openssl verify -CAfile /etc/ssl/PiAPCA/PiAP_CA.pem /etc/ssl/PiAPCA/certs/PiAP_SSL.pem | tee -a "${PIAP_LOG_PATH}" 2>/dev/null ;
	message "Certificate has expired. Recommend rebuilding cert links"
	echo "sudo rm -vf /etc/ssl/PiAPCA/certs/PiAP_SSL.pem || true"
	echo "# NOT SUPPORTED YET."
	message "DONE"
else
	message "SSL Certs seem fine."
fi
	umask 0027

for TIME_CHECKS in $( seq 30 720 ) ; do
if [[ ( $( find /etc/ssh -iname "*.pub" -ctime +"${TIME_CHECKS:-30}" -print0 2>/dev/null | wc -l ) -ge 1 ) ]] ; then
	message "Applying HOTFIX - SSH key rotation for Beta"
	find /etc/ssh -iname "*.pub" -ctime +"${TIME_CHECKS:-30}" -print0 2>/dev/null | xargs -0 -L1 rm -vf ; wait ;
	sudo ssh-keygen -A ; wait ;
	message "DONE"
	message "AFTER LOGGING OUT of this ssh session YOU MUST REMOVE TRUST OF THE OLD KEY by running: ssh-keygen -R ${HOSTNAME:-pocket.piap.local}"
	message "The NEW keys you will need to verify are:"
	find /etc/ssh -iname "*.pub" -print0 2>/dev/null | xargs -0 -L1 sudo ssh-keygen -l -v -f | tee -a "${PIAP_LOG_PATH}" 2>/dev/null;
fi
done

if [[ ( $( find /lib/clamav -iname "*.tmp" -print0 2>/dev/null | wc -l ) -ge 1 ) ]] ; then
	message "Applying HOTFIX - clear junk files: clamav temps"
	sudo rm -vfR /var/lib/clamav/*.tmp || true ; 
	wait ;
	sudo freshclam || true ;
	wait ;
	message "DONE"
fi

message "Restarting services."
sudo service php5-fpm start 2>/dev/null || sudo service php7.0-fpm start 2>/dev/null || ROLL_BACK=1 ;
if [[ ${CI} ]] ; then
	mv -vf /etc/nginx/sites-available/PiAP /etc/nginx/sites-available/PiAP.tmp 2>/dev/null || ROLL_BACK=1 ;
	sed -E -e 's/10.0.40.1://g' /etc/nginx/sites-available/PiAP.tmp 2>/dev/null | tee /etc/nginx/sites-available/PiAP || ROLL_BACK=3 ;
	rm -vf /etc/nginx/sites-available/PiAP.tmp || ROLL_BACK=1 ;
fi
sudo service nginx start || sudo rm -vf /etc/nginx/sites-enabled/default 2>/dev/null || true && sudo service nginx start || ROLL_BACK=1 ;
sudo service nginx status || sudo systemctl status nginx.service || true ;
sudo service php5-fpm restart 2>/dev/null || sudo service php7.0-fpm restart 2>/dev/null || ROLL_BACK=1 ;
sudo service clamav-freshclam restart 2>/dev/null || true ;
sudo service ntp restart 2>/dev/null || true ;
sudo /srv/PiAP/bin/service_AP_heal.bash || ROLL_BACK=1 ;
message "DONE"


if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
SSH_PORT="$(echo "${SSH_CONNECTION}" | cut -d\  -f 4 )"
SSH_SERVER="$(echo "${SSH_CONNECTION}" | cut -d\  -f 3 )"
( test -x /usr/bin/raspi-config 2>/dev/null && sudo /opt/PiAP/bin/set_LED_status_Agro.bash 2>/dev/null ) || true
message "Status: Doctor failed."
message "Please report this issue at https://github.com/reactive-firewall/Pocket-PiAP/issues"
message "[BETA] Please include the contents of this log \"${PIAP_LOG_PATH}\""
if [[ $CI ]] ; then
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
	message "[BETA] GIT ENV"
	${GIT_GPG_CMD} --list-sigs
	sudo git show --show-signature | grep -F ": " || true
	git config --list
	message "[BETA] PYTHON ENV"
	python3 --version
	python3 -m piaplib.pocket book version --all || true
	message "[BETA] WEB ENV"
	php --version
	head -n 4000 /etc/nginx/sites-available/PiAP || message "Missing /etc/nginx/sites-available/PiAP"
	head -n 4000 /etc/nginx/sites-available/default || message "Missing /etc/nginx/sites-available/default"
	sudo nginx -t -c /etc/nginx/nginx.conf || true
fi
echo "[BETA] To copy logs localy without logging out you can open another Terminal and run:"
echo "     scp -2 -P ${SSH_PORT:-22} -r ${LOGNAME:-youruser}@${SSH_SERVER:-$HOSTNAME}:${PIAP_LOG_PATH} ~/Desktop/PiAP_BUG_Report_logs.log"
else
(test -x /usr/bin/raspi-config 2>/dev/null && sudo /opt/PiAP/bin/set_LED_status_Ready.bash ) || true
message "Status: Doctor seemed to work. (check by logging in to the Web interface)"
fi
message "--------------------[LOG]----------------------"
head -n 9999999 "${PIAP_LOG_PATH}" || true ; wait ;

message "[DONE] SCRIPT IS NOW DONE. SAFE TO MOVE TO NEXT STEP"
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
	message "[NEXT] Verify backups were restored. [This is not a sure thing]"
	message "[NEXT] copy logs for bug report."
	echo "[BETA] To copy logs localy without logging out you can open another Terminal and run:"
	echo "	scp -2 -P ${SSH_PORT:-22} -r ${LOGNAME:-youruser}@${SSH_SERVER:-$HOSTNAME}:${PIAP_LOG_PATH} ~/Desktop/PiAP_BUGReport_logs.log"
	message "[NEXT] submit bug report."
else
	message "[OPTIONAL] Restart Pocket to compleate OS mantinance."
fi
sudo -k
exit ${ROLL_BACK:-3} ;


