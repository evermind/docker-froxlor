FROM debian:10-slim as build

# Initial setup
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get -y install curl wget apt-utils gnupg2

# Configure APT repositories
ADD config/sources.list /etc/apt/sources.list

# Update the system
RUN curl -s https://deb.froxlor.org/froxlor.gpg | apt-key add - && \
    curl -s https://www.liveconfig.com/liveconfig.key | apt-key add - && \
    apt-get update && \
    # upgrade everything
    apt-get -y dist-upgrade

# install and configure the init system
RUN apt-get install -y openrc busybox && \
    # configure the init system
    sed -i /etc/rc.conf \
      # Allow any env variable to be passed through init into the container
      -e 's|#rc_env_allow=".*"|rc_env_allow="\*"|g' \
      # Tell the init system that some services are already provided
      -e 's|#rc_provide=".*"|rc_provide="loopback net"|g' \
      # Set docker as subsystem
      -e 's|#rc_sys=".*"|rc_sys="docker"|g'

# configure inittab for busybox-init
ADD config/inittab /etc/inittab

# Install apache+php+froxlor and dependencies
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
      apache2 libapache2-mod-fcgid apache2-suexec-pristine \
      libapache2-mod-php \
      php-curl php-cli php-fpm imagemagick \
      froxlor html2text cron \
      # Install some more useful tools
      less nano

# configure froxlor to use externalized userdata file
RUN mkdir -p /var/system/froxlor && \
    chown www-data.www-data /var/system/froxlor && \
    ln -s /var/system/froxlor/userdata.inc.php /var/www/froxlor/lib/userdata.inc.php

# Add initial froxlor crontab
ADD config/froxlor-initial-crontab /etc/cron.d/froxlor

# Configure apache
ADD config/00_default_froxlor_port_8088.conf /etc/apache2/sites-enabled/00_default_froxlor_port_8088.conf
ADD config/acme.conf /etc/apache2/sites-enabled/acme.conf
RUN a2dissite 000-default && \
    a2enmod ssl headers suexec proxy_fcgi fcgid lbmethod_byrequests actions rewrite \
      proxy_http proxy_ajp proxy_balancer

# configure libnss-extrausers
RUN apt-get install libnss-extrausers && \
    mkdir -p /var/lib/extrausers && \
    touch /var/lib/extrausers/passwd && \
    touch /var/lib/extrausers/group && \
    touch /var/lib/extrausers/shadow
ADD config/nsswitch.conf /etc/nsswitch.conf


# configure awstats
RUN apt-get install -y --no-install-recommends awstats && \
    ln -s /usr/share/awstats/tools/awstats_buildstaticpages.pl /usr/bin/awstats_buildstaticpages.pl && \
    mv /etc/awstats/awstats.conf /etc/awstats/awstats.model.conf && \
    sed -i.bak 's/^DirData/# DirData/' /etc/awstats//awstats.model.conf && \
    sed -i.bak 's|^\\(DirIcons=\\).*$|\\1\\"/awstats-icon\\"|' /etc/awstats//awstats.model.conf && \
    echo "# disabled by froxlor docker setup" > /etc/cron.d/awstats

# configure logrotate
RUN apt-get install -y --no-install-recommends logrotate
ADD config/froxlor-logrotate /etc/logrotate.d/froxlor

# configure ssh
RUN apt-get install -y --no-install-recommends openssh-server && \
    mkdir -p /var/system/ssh && \
    rm -f /etc/ssh/ssh_host_*_key* && \
    for t in dsa ecdsa ed25519 rsa; do \
      ln -s /var/system/ssh/ssh_host_${t}_key /etc/ssh/ssh_host_${t}_key; \
    done && \
    mkdir -p /root/.ssh && \
    ln -s /var/system/ssh/authorized_keys /root/.ssh/authorized_keys

# create and activate initalizing script for system start
ADD config/prepare-system.sh /etc/init.d/prepare-system.sh
ADD config/prepare-froxlor.php /etc/init.d/prepare-froxlor.php
RUN rc-update add prepare-system.sh boot

# Check froxlor prerequisites to ensure all requirements are met
RUN HTTP_ACCEPT_LANGUAGE="en" php /var/www/froxlor/install/install.php 2>&1 | html2text && \
    HTTP_ACCEPT_LANGUAGE="en" php /var/www/froxlor/install/install.php 2>&1 | html2text | grep -e 'All requirements are satisfied' > /dev/null

# Patching froxlor to allow 0.0.0.0 as IP address
ADD config/froxlor-pr-760.diff /tmp/froxlor-pr-760.diff
RUN apt-get install -y --no-install-recommends patch && \
    cd /var/www/froxlor && patch -p1 < /tmp/froxlor-pr-760.diff

# Adding extra PHP versions
RUN apt-get install -y --no-install-recommends \
      php-5.6-opt php-5.6-opt-apcu php-5.6-opt-dba php-5.6-opt-imagick \
      php-7.0-opt php-7.0-opt-apcu php-7.0-opt-dba php-7.0-opt-imagick \
      php-7.1-opt php-7.1-opt-apcu php-7.1-opt-dba php-7.1-opt-imagick && \
    rc-update add php56-fpm default && \
    rc-update add php70-fpm default && \
    rc-update add php71-fpm default

# cleanup, remove unused services and files
RUN rc-update del mysql default && \
    rc-update del rsync default && \
    rm -f /etc/init.d/hwclock.sh /etc/init.d/procps && \
    rm -rf /tmp /var/lib/apt/lists/*


# Squash image layers into one
#FROM scratch
#COPY --from=build / /

# Required for openrc to run without warnings
VOLUME ["/sys/fs/cgroup","/var/customers","/var/system"]

ENTRYPOINT ["/bin/busybox","init"]
