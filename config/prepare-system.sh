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

echo -n "* Setting up froxlor data dirs ... "
mkdir -p /var/froxlor-data/userdata
[ -e /var/froxlor-data/userdata/userdata.inc.php ] || touch /var/froxlor-data/userdata/userdata.inc.php
chown -R www-data.www-data /var/froxlor-data/userdata
mkdir -p /var/customers/logs
mkdir -p /var/customers/tmp
chmod 1777 /var/customers/tmp
echo "done."

/usr/bin/php /etc/init.d/prepare-froxlor.php
