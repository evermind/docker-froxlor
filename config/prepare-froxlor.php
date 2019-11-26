<?php

require "/var/froxlor-data/userdata/userdata.inc.php";

if (!isset($sql)) {
    print ("Froxlor not yet configured, skipping init process\n");
    return;
}

print ("Waiting for froxlor database ...");
$link = false;
error_reporting(E_ERROR | E_PARSE);
while (!$link) {
    $link = mysqli_connect($sql['host'], $sql['user'], $sql['password'],$sql['db']);
    if (!$link) {
        print(".");
        sleep(1);
    }
}
print (" available.\n");
error_reporting(E_ERROR | E_WARNING | E_PARSE);

print ("Initializing froxlor configurations...\n");
exec("/usr/bin/php -q /var/www/froxlor/scripts/froxlor_master_cronjob.php --tasks 1 --force");
