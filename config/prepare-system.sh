#!/bin/bash
### BEGIN INIT INFO
# Provides:          prepare-system
# Default-Start:     2 3 4 5
# Short-Description: prepare system at boot time
# Description:       prepare system at boot time
### END INIT INFO

if [ "$1" != "start" ]; then
  # only start is supported
  exit 0
fi

echo -n "* Creating and linking ssh keys ... "
mkdir -p /var/system/ssh
for t in dsa ecdsa ed25519 rsa; do
  [ -e /var/system/ssh/ssh_host_${t}_key ] || ssh-keygen -t $t -N "" -f /var/system/ssh/ssh_host_${t}_key
done
[ -e /var/system/ssh/authorized_keys ] || touch /var/system/ssh/authorized_keys
mkdir -p /root/.ssh
chmod 600 /root/.ssh
[ -e /root/.ssh/authorized_keys ] || ln -s /var/system/ssh/authorized_keys /root/.ssh/authorized_keys
echo "done."

echo -n "* Setting up log dirs ... "
mkdir -p /var/log/apache2 /var/log/apt
chown root.adm /var/log/apache2
mkdir -p /var/log/proftpd 

echo "done."

if [ ! -z "${NAT_PUBLIC_IP}" ]; then
  echo -n "* Setting FTP masquerade address to ${NAT_PUBLIC_IP} .."
  sed -i -E "s/#?\\s+MasqueradeAddress.*/MasqueradeAddress ${NAT_PUBLIC_IP}/" /etc/proftpd/proftpd.conf
  echo "done."
fi

if [ ! -z "${SMTP_HOST}" ]; then
  echo -n "* Setting up smtp relay via ${SMTP_HOST} ... "
  cat << EOF > /etc/msmtprc
defaults
auth           off
tls            off

account        mailrelay
host           ${SMTP_HOST}
from           ${SMTP_SENDER_ADDRESS}

account default : mailrelay
EOF
  echo "done."
fi

echo -n "* Setting up froxlor data dirs ... "
mkdir -p /var/system/froxlor
[ -e /var/system/froxlor/userdata.inc.php ] || touch /var/system/froxlor/userdata.inc.php
chown -R www-data.www-data /var/system/froxlor
mkdir -p /var/customers/logs
mkdir -p /var/customers/tmp
chmod 1777 /var/customers/tmp
echo "done."

echo -n "* Setting up FTPS certificates if not already exists "
mkdir -p /var/system/ssl/certs
mkdir -p /var/system/ssl/private
[ -f /var/system/ssl/certs/proftpd.crt ] || openssl req -new -x509 -newkey rsa:4096 -days 3650 -nodes -out /var/system/ssl/certs/proftpd.crt -keyout /var/system/ssl/private/proftpd.key -subj "${FTP_TLS_SUBJECT}"
[ -f /var/system/ssl/certs/proftpd_ec.crt ] || openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp521r1) -keyout /var/system/ssl/private/proftpd_ec.key -out /var/system/ssl/certs/proftpd_ec.crt -days 3650 -subj "${FTP_TLS_SUBJECT}"
chmod 0600 /var/system/ssl/private/proftpd.key /var/system/ssl/private/proftpd_ec.key
echo "done."


/usr/bin/php /etc/init.d/prepare-froxlor.php
