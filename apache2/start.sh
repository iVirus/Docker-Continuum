#!/bin/bash
chown www-data: /config

if [ ! -d /config/sessions ]; then
    install --owner www-data --group www-data --directory /config/sessions
fi

if [ ! -d /config/httpd/ssl ]; then
    install --directory /config/httpd/ssl
    ln --symbolic --force /etc/ssl/certs/ssl-cert-snakeoil.pem /config/httpd/ssl/continuum.crt
    ln --symbolic --force /etc/ssl/private/ssl-cert-snakeoil.key /config/httpd/ssl/continuum.key
fi

pidfile=/var/run/apache2/apache2.pid

if [ -f ${pidfile} ]; then
    pid=$(cat ${pidfile})

    if [ ! -d /proc/${pid} ] || [ -d /proc/${pid} -a $(basename $(readlink /proc/${pid}/exe)) != 'apache2' ]; then
        rm ${pidfile}
    fi
fi

$(which su) \
    -c $(which schedule.php) \
    -s /bin/bash \
    www-data &

sleep 1

$(which su) \
    -c $(which notifications.php) \
    -s /bin/bash \
    www-data &

sleep 1

exec $(which apache2ctl) \
    -D FOREGROUND \
    -D ${HTTPD_SSL:-SSL} \
    -D ${HTTPD_REDIRECT:-REDIRECT}
