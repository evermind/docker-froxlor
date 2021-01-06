[![Build Status](https://travis-ci.org/evermind/docker-froxlor.svg?branch=master)](https://travis-ci.org/evermind/docker-froxlor)

# About

This is a debian 10 system which runs apache, php and froxlor web hosting panel.

- Using busybox+openrc as minimal, sysv+docker compatible init system
- pre-configured system for froxlor
- debian auto-updates (via cron-apt)
- external database, external ftp server, allowing independent rolling-updates

The container contains a config that matches with Froxlor 0.10.6. It might change over time, required changes can be reviewed at
https://config.froxlor.org/?distribution=debian_buster&from=0.10.6&to=9999&submit=


# Setup (Kubernetes)

* Deploy using the helm chart
* The admin interface will be available on port 8088 (without SSL!). It can be used for initial setup and can later be used as emergency admin access

## Password restrictions

Due to a certain shell logic no special characters may be used! Only use longer alpha-numeric passwords - the longer the better.


## Pipework setup

* Starting with chart version 0.3.0 pipework is supported to obtain an external directly routet IP address. This allows to run multiple
  froxlor deployments on one kubernetes node without interfering each other
* TODO: document it

## Initial setup dialog

* Go to your http://{host or ip}:8088
* Mysql hostname: name of the mysql service (e.g. froxlor-mysql)
* Mysql password / rootPassword as specified in values.yaml
* A secure admin password
* A server name that resolves to the host
* IP address 0.0.0.0 (=wildcard) because the POD IP can change

## System setup

* login as admin

### System Setup

* System -> Settings -> Panel settings
    * setup mail sender/recipient
    * phpMyAdmin URL -> TODO
    * Allow moving domains between admins
    * Allow moving domains between customers
    * Hide mail settings in customer panel (there's no mail support in this docker container yet)
* System -> Settings -> Account settings
    * Allow multiple login
    * Allow login with domains
    * Allow password reset by admins
* System -> Settings -> SSL settings
    * Activate + Save
    * Enable Let's Encrypt
    * Switch to the Acme2 Test endpoint until everything works!
    * Disable DNS validation before creating  Let's Encrypt certificate (needed if Default SSL IP is 0.0.0.0:443 (hostPort))
* Resources -> IPs and Ports
    * For deployments using hostPort/hostIp
        * add IP 0.0.0.0, Port 80, Disable "Create Listen statement" (if not pressent)
        * add IP 0.0.0.0, Port 443, Disable "Create Listen statement", Enable "SSL Port"
    * For deployments using pipework and directly assigned IPs
        * Primary IP, Port 80 should already be there
        * add Primary IP, Port 443, Disable "Create Listen statement", Enable "SSL Port"
* System -> Settings -> System settings
    * Use domain name as default value for DocumentRoot path
    * IP-address: 0.0.0.0 (hostPort) or primary IP (pipework)
    * Default IP/Port: 0.0.0.0:80 (hostPort) or primary IP:80 (pipework)
    * Default SSL IP/Port: 0.0.0.0:443 (hostPort) or primary IP:443 (pipework)
    * Use libnss-extrausers instead of libnss-mysql
    * MySQL-Access-Hosts: 10.42.0.0/255.255.0.0,localhost (This is the default POD Network, change if your's differs)
    * Use libnss-extrausers instead of libnss-mysql
    * TODO: Set mailer to use SMTP
* Resources -> IPs and Ports
    * Delete the 10.42.X.X IP (if pressent, only with hostPort deployment)
* System -> Settings -> PHP-FPM
    * Activate + Save
* System -> Settings -> Froxlor VirtualHost settings
    * Access Froxlor directly via the hostname
    * Optional: Domain aliases for froxlor vhost
    * Enable Let's Encrypt for the froxlor vhost
    * Enable SSL-redirect for the froxlor vhost
    * Do not enable PHP-FPM for the Froxlor vHost (needs extra users which are not yet pressent in the docker image)
* System -> Settings -> Statistic settings
    * Enable AWstats statistics
* System -> Settings -> Nameserver settings 
    * Deactivate + Save
* System -> Settings -> Cronjob settings
    * Allow automatic database updates
* PHP -> PHP-FPM versions -> Edit "System default"
    * Rename to "System PHP"
    * php-fpm restart command: /usr/sbin/service php7.3-fpm restart
    * Configuration directory of php-fpm: /etc/php/7.3/fpm/pool.d/
* System -> Configuration
    * I have configured the System (get rid of the red warning badge)

### PHP / FPM Configurations

* php 5.6
    * Restart command: /etc/init.d/php56-fpm restart
    * Config path: /etc/php-fpm/php56-fpm.d/
* php 7.0
    * Restart command: /etc/init.d/php70-fpm restart
    * Config path: /etc/php-fpm/php70-fpm.d/
* php 7.1
    * Restart command: /etc/init.d/php71-fpm restart
    * Config path: /etc/php-fpm/php71-fpm.d/
* php 7.2
    * Restart command: /etc/init.d/php72-fpm restart
    * Config path: /etc/php-fpm/php72-fpm.d/
* php 7.3
    * Restart command: /etc/init.d/php73-fpm restart
    * Config path: /etc/php-fpm/php73-fpm.d/
* php 7.4
    * Restart command: /etc/init.d/php74-fpm restart
    * Config path: /etc/php-fpm/php74-fpm.d/


### SSH Setup

* The root user has no password, add your pub key in ssh/authorized_keys in the "system" volume

### PHPMyAdmin Setup

If PHPMyAdmin is deployed via helm chart (enable with phpmyadmin.enabled=true), a service is startet at `http://{release-name}-phpmyadmin/`.

To enable access to it go to Resources -> IPs and Ports -> Port 443 and add the following

* to Webserver-SSL-Configuration -> custom SSL vHost Configuration (for the froxlor VHost only)
* or to Default SSL vHost Configuration (for the froxlor VHost only)
* replacing `{release-name}` with the actual release name

```
ProxyPass "/phpmyadmin/" "http://{release-name}-phpmyadmin/"
ProxyPassReverse "/phpmyadmin/" "http://{release-name}-phpmyadmin/"
```

# Upgrade docker image

* change version information at Chart.yaml and values.yaml
* add current froxlor version as shown in console (new available version) under appVersion in Chart.yaml
* publih new tag for chart

Travis will build a new Chart for repository. Dockerhub will build a new Docker image based on git tag https://hub.docker.com/repository/docker/evermind/froxlor/tags?page=1&ordering=last_updated

# Ideas

- Use lxcfs to improve user experience: https://medium.com/@Alibaba_Cloud/kubernetes-demystified-using-lxcfs-to-improve-container-resource-visibility-86f48ce20c6
