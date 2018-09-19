#! /bin/bash
cd ${TEMPDIR}
sudo dd if=/dev/hwrng bs=1024 count=4096 of=./.rand_seed.data
wait ;
openssl genrsa -rand ./.rand_seed.data -out ./ssl_cert_nginx.key 4096 ; wait ;
openssl req -new -outform PEM -out ./ssl-cert-nginx.csr -key ./ssl_cert_nginx.key -subj "/CN=${HOSTNAME}.PiAP.local/OU=PiAP.local/O=PiAP\ Network/" ; wait ;
sudo mv -vf ./ssl_cert_nginx.key /etc/ssl/private/ssl-cert-nginx.key ; sudo shred -zero ./.rand_seed.data 2>/dev/null ; wait ; sudo rm -vf ./.rand_seed.data
sudo chown 0:daemon /etc/ssl/private/ssl-cert-nginx.key
sudo chmod 640 /etc/ssl/private/ssl-cert-nginx.key
mv -vf ./ssl-cert-nginx.csr ~/ssl-cert-nginx.csr
openssl req -in ~/ssl-cert-nginx.csr -noout -text
exit 0 ;
