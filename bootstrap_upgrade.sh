#! /bin/bash

ROLL_BACK=0

echo "updating system to latest."
sudo apt-get clean || ROLL_BACK=1 ;
sudo apt-get autoclean || ROLL_BACK=1 ;
sudo apt-get update || ROLL_BACK=1 ;
sudo apt-key update || ROLL_BACK=1 ;
sudo apt-get --only-upgrade dist-upgrade || ROLL_BACK=1 ;
sudo apt-get autoremove || ROLL_BACK=1 ;

cd /tmp ;
test -d /var/ || exit 2 ;
test -d /var/opt/ || mkdir -m 755 /var/opt/ && chown 0:0 /var/opt/ || exit 2 ;
test -d /var/opt/PiAP/ || mkdir /var/opt/PiAP/ || exit 2 ;
test -d /var/opt/PiAP/backups/ || mkdir /var/opt/PiAP/backups/ || exit 2 ;
chown 0:0 /var/opt/PiAP/backups/ || true ;
chown 750 /var/opt/PiAP/backups/ || true ;
chown 0:0 /var/opt/PiAP/ || true ;
chown 755 /var/opt/PiAP/ || true ;
sudo mv -f /var/opt/PiAP/backups/PiAP /var/opt/PiAP/backups/PiAP_OLD
echo "Backing up pre-upgrade version"
sudo cp -vfRpub /srv/PiAP /var/opt/PiAP/backups/PiAP || exit 3 ;
echo "disabling web-server to prevent inconsistent state. All sessions will be logged out."
sudo service nginx stop ;
sudo service php5-fpm stop ;
echo "Fetching upgrade files... [FIX ME]"
git clone -b master https://github.com/reactive-firewall/PiAP-Webroot.git
cd ./PiAP-Webroot || ROLL_BACK=2 ;
echo "SKIPPING TRUST CHECK. [BETA TEST] [FIX ME]"
#checkout stable version
#verify stable version
#git tag -v [tag-name]
echo "Attempting upgrading. [BETA TEST]"
echo "DO NOT INTURUPT OR POWER OFF. [BETA TEST]"
sudo make install || ROLL_BACK=2 ;
make clean
if [[ ( ${ROLL_BACK:-3} -gt 0 ) ]] ; then
	echo "Upgrading FAILED. DO NOT INTURUPT OR POWER OFF."
	echo "Rolling back from backup. DO NOT INTURUPT OR POWER OFF."
	echo "... cleaning up mess from failed upgrade"
	sudo rm -vfR /srv/PiAP || true ;
	sudo cp -vfRpub /var/opt/PiAP/backups/PiAP /srv/PiAP || echo "FATAL error: device will need full reset. Please report this issue at \"https://github.com/reactive-firewall/PiAP-Webroot/issues\" (include as much detail as posible) and reconfigure your device (OS re-install + PiAP fresh install). You found a bug. [BUGS] [FIX ME]"
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


