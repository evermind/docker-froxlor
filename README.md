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
* Resources -> IPs and Ports
    * add IP 0.0.0.0, Port 80, Disable "Create Listen statement" (if not pressent)
    * add IP 0.0.0.0, Port 443, Disable "Create Listen statement", Enable "SSL Port"
* System -> Settings -> System settings
    * Use domain name as default value for DocumentRoot path
    * IP-address: 0.0.0.0
    * Default IP/Port: 0.0.0.0:80
    * Default SSL IP/Port: None
    * Use libnss-extrausers instead of libnss-mysql
    * MySQL-Access-Hosts: 10.42.0.0/255.255.0.0,localhost (This is the default POD Network, change if your's differs)
    * Use libnss-extrausers instead of libnss-mysql
    * TODO: Set mailer to use SMTP
* Resources -> IPs and Ports
    * Delete the 10.42.X.X IP (if pressent)
* System -> Settings -> PHP-FPM
    * Activate + Save
* System -> Settings -> Froxlor VirtualHost settings
    * Access Froxlor directly via the hostname
    * Optional: Domain aliases for froxlor vhost
    * Enable Let's Encrypt for the froxlor vhost
    * Enable SSL-redirect for the froxlor vhost
    * Enable PHP-FPM for the Froxlor vHost
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

### SSH Setup

* The root user has no password, add your pub key in ssh/authorized_keys in the "system" volume


# Ideas

- Use lxcfs to improve user experience: https://medium.com/@Alibaba_Cloud/kubernetes-demystified-using-lxcfs-to-improve-container-resource-visibility-86f48ce20c6
