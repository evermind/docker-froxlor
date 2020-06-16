#!/bin/bash

/usr/bin/php -q /var/www/froxlor/scripts/froxlor_master_cronjob.php --tasks
/usr/bin/php -q /var/www/froxlor/scripts/froxlor_master_cronjob.php --letsencrypt
/usr/bin/php -q /var/www/froxlor/scripts/froxlor_master_cronjob.php --tasks
