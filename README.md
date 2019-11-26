# About

This is a debian 10 system which runs apache, php and froxlor web hosting panel.

- Using busybox+openrc as minimal, sysv+docker compatible init system
- pre-configured system for froxlor
- debian auto-updates (via cron-apt)
- external database, external ftp server, allowing independent rolling-updates

The container contains a config that matches with Froxlor 0.10.6. It might change over time, required changes can be reviewed at
https://config.froxlor.org/?distribution=debian_buster&from=0.10.6&to=9999&submit=


# Setup

* Deploy using docker-compose or helm chart
* The admin interface will be available on port 8088 (without SSL!). It can be used for initial setup and can later be used as emergency admin access

## Initial setup dialog

TBD


# Ideas

- Use lxcfs to improve user experience: https://medium.com/@Alibaba_Cloud/kubernetes-demystified-using-lxcfs-to-improve-container-resource-visibility-86f48ce20c6