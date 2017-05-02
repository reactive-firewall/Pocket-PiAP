#!/bin/bash
#make chroot jail
JAIL_NAME=${JAIL_NAME:-"jail_${PPID:-default}"}
cd /sandbox
sudo mkdir -p 0751 ./${JAIL_NAME:-./jail}
sudo chown 0:0 ./${JAIL_NAME:-./jail}
sudo mkdir -vp ./${JAIL_NAME:-./jail}/etc ; wait ;
sudo mkdir -vp ./${JAIL_NAME:-./jail}$(dirname $(which bash)) ; wait ;
sudo cp -pvf $(which bash) ./${JAIL_NAME:-./jail}$(which bash) ; wait ;
#ldd $(which bash)
for EACH_DEPENDANCY in libtinfo.so.5 libdl.so.2 libc.so.6 ../ld-linux-x86-64.so.2 ; do
sudo mkdir -vp ./${JAIL_NAME:-./jail}/lib/x86_64-linux-gnu/ ; wait ;
sudo cp -pvf /lib/x86_64-linux-gnu/$EACH_DEPENDANCY ./${JAIL_NAME:-./jail}/lib/x86_64-linux-gnu/$EACH_DEPENDANCY ; wait ; done ;
sudo mkdir -vp ./${JAIL_NAME:-./jail}/lib64/
sudo cp -pvf /lib64/ld-linux-x86-64.so.2 ./${JAIL_NAME:-./jail}/lib64/ld-linux-x86-64.so.2

sudo mkdir -vp ./${JAIL_NAME:-./jail}$(dirname $(which ${1:-ls})) ; wait ;
( ( sudo /usr/local/bin/ldd-tool.bash $(which ${1:-ls}) | xargs -L 1 sudo /usr/local/bin/ldd-tool.bash ) | sort ; sudo /usr/local/bin/ldd-tool.bash $(which ${1:-ls}) ) | sort | uniq | xargs -L 1 -I{} sudo cp -vfpub {} /sandbox/${JAIL_NAME:-./jail}/{} ;

sudo cp -vfpub $(which ${1:-ls}) /sandbox/${JAIL_NAME:-./jail}/$(which ${1:-ls}) ;

wait ;

sudo cp -Rpvf /sandbox/${JAIL_NAME:-./jail} /home/chroot/${JAIL_NAME:-./jail}


cd /home/chroot
sudo chroot ./${JAIL_NAME:-./jail}/ bash --login

wait ;

