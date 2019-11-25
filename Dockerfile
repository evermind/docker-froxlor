FROM debian:10-slim

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get -y install curl wget apt-utils gnupg2 && \
    # configure apt
    rm /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian buster main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian buster-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://debian.froxlor.org/ buster main" >> /etc/apt/sources.list && \
    curl -s https://deb.froxlor.org/froxlor.gpg | apt-key add - && \
    echo "deb http://repo.liveconfig.com/debian/ buster php" >> /etc/apt/sources.list && \
    curl -s https://www.liveconfig.com/liveconfig.key | apt-key add - && \
    apt-get update && \
    # upgrade everything
    apt-get -y dist-upgrade && \
    # install basic tools and init system
    apt-get install -y openrc busybox && \
    # configure the init system
    sed -i /etc/rc.conf \
      -e 's|#rc_env_allow=".*"|rc_env_allow="\*"|g' \
      -e 's|#rc_provide=".*"|rc_provide="loopback net"|g' \
      -e 's|#rc_sys=".*"|rc_sys="docker"|g' && \
    # let busybox start openrc so that we have propper shutdown handling
    echo "::sysinit:/sbin/openrc sysinit\n::wait:/sbin/openrc boot\n::wait:/sbin/openrc default" \
      > /etc/inittab && \
    # Install some more useful tools
    apt-get install -y less nano

RUN export DEBIAN_FRONTEND=noninteractive && \
    # Install apache+php+froxlor
    apt-get install -y --no-install-recommends \
      apache2 libapache2-mod-fcgid apache2-suexec-pristine \
      libapache2-mod-php \
      php-curl php-cli php-fpm imagemagick \
      froxlor html2text

RUN export DEBIAN_FRONTEND=noninteractive && \
    # TODO: mit installieren
    apt-get install -y --no-install-recommends \
      cron

RUN \
    # Check froxlor prerequisites
    HTTP_ACCEPT_LANGUAGE="en" php /var/www/froxlor/install/install.php 2>&1 | html2text && \
    HTTP_ACCEPT_LANGUAGE="en" php /var/www/froxlor/install/install.php 2>&1 | html2text | grep -e 'All requirements are satisfied' > /dev/null

RUN \
    a2dissite 000-default && \
    # configure froxlor default vhost
    echo '\
Listen *:8088\n\
NameVirtualHost *:8088\n\
<VirtualHost *:8088>\n\
        ServerAdmin webmaster@localhost\n\
        DocumentRoot /var/www/froxlor\n\
        ErrorLog ${APACHE_LOG_DIR}/error.log\n\
        CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-enabled/00_default_froxlor_port_8088.conf

RUN \
    # configure froxlor to use external userdata file
    mkdir -p /var/froxlor-data/userdata && \
    chown www-data.www-data /var/froxlor-data/userdata && \
    ln -s /var/froxlor-data/userdata/userdata.inc.php /var/www/froxlor/lib/userdata.inc.php

RUN \
    # Add init script (special encoding of header to avoid that it's ignored as a dockerfile comment...)
    echo '#!/bin/sh\n\
\n### BEGIN INIT INFO\
\n# Provides:          prepare-froxlor\
\n# Default-Start:     2 3 4 5\
\n# Short-Description: prepare froxlor at boot time\
\n# Description:       prepare froxlor at boot time\
\n### END INIT INFO\n\
echo $0 $1\n\
if [ "$1" != "start" ]; then\n\
  exit 0\n\
fi\n\
\n\
echo "Setting froxlor userdata permissions"\n\
mkdir -p /var/froxlor-data/userdata\n\
[ -e /var/froxlor-data/userdata/userdata.inc.php ] || touch /var/froxlor-data/userdata/userdata.inc.php\n\
chown -R www-data.www-data /var/froxlor-data/userdata\n\
mkdir -p /var/customers/logs\n\
mkdir -p /var/customers/tmp\n\
chmod 1777 /var/customers/tmp\n\
' \
      > /etc/init.d/prepare-froxlor.sh && \
    chmod 0755 /etc/init.d/prepare-froxlor.sh && \
    rc-update add prepare-froxlor.sh boot && \
    # Create froxlor initial crontab (on success it's replaced by the default crontab)
    echo '\n\
* * * * * root /usr/bin/php -q /var/www/froxlor/scripts/froxlor_master_cronjob.php --tasks 1 --force > /dev/null 2>&1\n\
'\
      > /etc/cron.d/froxlor

RUN \
    # cleanup, remove unused services
    rc-update del mysql default && \
    rc-update del rsync default && \
    rm -f /etc/init.d/hwclock.sh /etc/init.d/procps


# Required for openrc to run without warnings
VOLUME ["/sys/fs/cgroup","/var/customers","/var/froxlor-data"]

ENTRYPOINT ["/bin/busybox","init"]