#!/bin/sh
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
echo "done."

echo -n "* Setting up froxlor data dirs ... "
mkdir -p /var/system/froxlor
[ -e /var/system/froxlor/userdata.inc.php ] || touch /var/system/froxlor/userdata.inc.php
chown -R www-data.www-data /var/system/froxlor
mkdir -p /var/customers/logs
mkdir -p /var/customers/tmp
chmod 1777 /var/customers/tmp
echo "done."

/usr/bin/php /etc/init.d/prepare-froxlor.php
