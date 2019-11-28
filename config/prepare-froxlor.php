<?php

require "/var/system/froxlor/userdata.inc.php";

if (!isset($sql)) {
    exec("echo 'Cron: Froxlor not yet configured, skipping init process' >/proc/1/fd/1");
    return;
}

error_reporting(E_ERROR | E_PARSE);
$link = mysqli_connect($sql['host'], $sql['user'], $sql['password'],$sql['db']);
if (!$link) {
    exec("echo 'Cron: Froxlor database not available.' >/proc/1/fd/1");
    return;
}
exec("echo 'Cron: Froxlor database available.' >/proc/1/fd/1");
error_reporting(E_ERROR | E_WARNING | E_PARSE);

exec("echo 'Cron: Initializing froxlor config.' >/proc/1/fd/1");
exec("/usr/bin/php -q /var/www/froxlor/scripts/froxlor_master_cronjob.php --force --debug >/proc/1/fd/1 2>&1");

?>