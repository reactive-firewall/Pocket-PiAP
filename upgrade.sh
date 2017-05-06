#! /bin/bash

ROLL_BACK=0

echo "updating system to latest."
sudo apt-get update || ROLL_BACK=1 ;
sudo apt-key update || ROLL_BACK=1 ;
sudo apt-get --only-upgrade --assume-yes dist-upgrade || ROLL_BACK=1 ;
sudo apt-get autoremove || ROLL_BACK=1 ;

cd /tmp ;
test -d /var/ || exit 2 ;
test -d /var/opt/ || mkdir -m 755 /var/opt/ && sudo chown 0:0 /var/opt/ || exit 2 ;
test -d /var/opt/PiAP/ || mkdir -m 755 /var/opt/PiAP/ || exit 2 ;
test -d /var/opt/PiAP/backups/ || mkdir -m 755 /var/opt/PiAP/backups/ || exit 2 ;
sudo chown 0:0 /var/opt/PiAP/backups/ || true ;
sudo chown 750 /var/opt/PiAP/backups/ || true ;
sudo chown 0:0 /var/opt/PiAP/ || true ;
sudo chown 755 /var/opt/PiAP/ || true ;
sudo rm -Rvf /var/opt/PiAP/backups/PiAP_OLD/ 2>/dev/null || true ;
sudo mv -f /var/opt/PiAP/backups/PiAP /var/opt/PiAP/backups/PiAP_OLD || true
echo "Backing up pre-upgrade version"
sudo cp -vfRpub /srv/PiAP /var/opt/PiAP/backups/PiAP || exit 3 ;
echo "disabling web-server to prevent inconsistent state. All sessions will be logged out."
sudo service nginx stop ;
sudo service php5-fpm stop ;
echo "Fetching upgrade files... [FIX ME]"
git clone -b master https://github.com/reactive-firewall/PiAP-Webroot.git || true ;
cd ./PiAP-Webroot || ROLL_BACK=2 ;
git fetch || ROLL_BACK=2 ;
git rebase || ROLL_BACK=2 ;
echo "SKIPPING TRUST CHECK. [BETA TEST] [FIX ME]"
#checkout stable version
#verify stable version
#git tag -v [tag-name]
echo "Attempting upgrading. [BETA TEST]"
echo "DO NOT INTURUPT OR POWER OFF. [BETA TEST]"
sudo make uninstall || ROLL_BACK=2 ;
sudo make install || ROLL_BACK=2 ;
make clean
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
	echo "Upgrading FAILED. DO NOT INTURUPT OR POWER OFF."
	echo "Rolling back from backup. DO NOT INTURUPT OR POWER OFF."
	echo "... cleaning up mess from failed upgrade"
	sudo mv -vfR /srv/PiAP /srv/PiAP_Failed || true ;
	sudo rm -vfR /srv/PiAP_Failed || true ;
	sudo cp -vfRpub /var/opt/PiAP/backups/PiAP /srv/PiAP || echo "FATAL error: device will need full reset. Please report this issue at \"https://github.com/reactive-firewall/PiAP-Webroot/issues\" (include as much detail as posible) and reconfigure your device (OS re-install + PiAP fresh install). You found a bug. [BUGS] [FIX ME]"
fi
echo "checking SSL Beta cert dates."
if [[ ( $( openssl verify -CAfile /etc/ssl/certs/ssl-cert-CA-nginx.pem /etc/ssl/certs/ssl-cert-nginx.pem 2>/dev/null | fgrep -c OK ) -le 0 ) ]] ; then
	echo "Applying HOTFIX - SSL Cert rotation for Beta"
	sudo openssl x509 -req -in /root/ssl-cert-nginx.csr -extfile /etc/ssl/PiAP_keyring.cfg -days 30 -extensions usr_cert -CA /etc/ssl/PiAP_CA/PiAP_CA.pem -CAkey /etc/ssl/private/ssl-cert-CA-nginx.key -CAcreateserial | fgrep --after-context=400 -e $"-----BEGIN CERTIFICATE-----" | sudo tee /etc/ssl/certs/ssl-cert-nginx.pem ; wait ; sudo fgrep --after-context=400 -e $"-----BEGIN CERTIFICATE-----" /etc/ssl/certs/ssl-cert-CA-nginx.pem | sudo tee -a /etc/ssl/certs/ssl-cert-nginx.pem ; wait ; sudo service nginx restart ;
else
	echo "Cert seems fine."
fi
if [[ ( $( find /etc/ssh -iname *.pub -ctime +30 -print0 2>/dev/null | wc -l ) -ge 1 ) ]] ; then
	echo "Applying HOTFIX - SSH key rotation for Beta"
	find /etc/ssh -iname *.pub -ctime +30 -print0 2>/dev/null | xargs -0 -L1 rm -vf ; wait ;
	sudo ssh-keygen -A ; wait ;
	echo ""
	echo "AFTER LOGGING OUT of this ssh session YOU MUST REMOVE TRUST OF THE OLD KEY by running: ssh-keygen -R ${HOSTNAME:-pocket.piap.local}"
	echo "The NEW keys you will need to verify are:"
	find /etc/ssh -iname *.pub -print0 2>/dev/null | xargs -0 -L1 sudo ssh-keygen -l -v -f ;
	echo ""
else
	echo "ssh keys seem fine."
fi
echo "restarting web-server."
sudo service php5-fpm start || ROLL_BACK=1 ;
sudo service nginx start || ROLL_BACK=1 ;
sudo service php5-fpm restart || ROLL_BACK=1 ;
echo ""
echo "DONE"
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
echo "Status: Upgrade failed."
echo "Please report this issue at https://github.com/reactive-firewall/Pocket-PiAP/issues"
else
echo "Status: Upgrade seemed to work."
fi
echo ""
echo "restart to compleate"

sudo -k
exit ${ROLL_BACK:-3} ;


