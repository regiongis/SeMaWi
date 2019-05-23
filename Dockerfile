FROM mediawiki:1.31.1

RUN apt-get update && apt-get -y install mysql-client curl git zip unzip

RUN mkdir /etc/semawi/
COPY composer.local.json /etc/semawi/composer.local.json
COPY db.sql /etc/semawi/db.sql

COPY res/LocalSettings.php /var/www/html/LocalSettings.php
COPY res/frb_logo.png /var/www/html/resources/assets/frb_logo.png

COPY entrypoint.sh /usr/local/bin/

CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
