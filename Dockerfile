FROM debian:jessie
MAINTAINER Josef Assad <josef@josefassad.com>
LABEL version="2018"

ENV DEBIAN_FRONTEND noninteractive

# We'll need the deb-src repositories since we're apt-get build-dep'ing
# python-lxml as part of getting gc2smwdaemon's virtualenv prepped
COPY sources.list.d/jessie-deb-src.list \
     /etc/apt/sources.list.d/jessie-deb-src.list

# Add php7
RUN apt-get update && \
    apt-get -y install wget ca-certificates apt-transport-https && \
    wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - && \
    echo "deb https://packages.sury.org/php/ jessie main" | tee /etc/apt/sources.list.d/php.list

# Get stack up
RUN apt-get update && \
    apt-get -y install mysql-client apache2 curl php git php-mbstring php-pear \
    php-mysql php-pgsql libapache2-mod-php virtualenv cron freetds-bin \
    tdsodbc php-odbc unixodbc odbcinst graphviz graphviz-dev imagemagick && \
    apt-get -y build-dep python-lxml

# Copy over the Mediawiki configs needed
RUN mkdir /etc/semawi/
COPY composer.local.json /etc/semawi/composer.local.json
COPY db.sql /etc/semawi/db.sql
ADD 001-semawi.conf /etc/apache2/sites-available/001-semawi.conf

# Installing the GC2 daemon
COPY scripts/installgc2daemon.sh /opt/installgc2daemon.sh
COPY scripts/syncgc2.sh /opt/syncgc2.sh
COPY gc2 /opt/gc2
RUN sh /opt/installgc2daemon.sh

# Slim down the image
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy over the apache wrapper
COPY scripts/entrypoint.sh /usr/local/bin/

# Start up apache
env APACHE_RUN_USER    www-data
env APACHE_RUN_GROUP   www-data
env APACHE_PID_FILE    /var/run/apache2.pid
env APACHE_RUN_DIR     /var/run/apache2
env APACHE_LOCK_DIR    /var/lock/apache2
env APACHE_LOG_DIR     /var/log/apache2
env LANG               C

EXPOSE 80

# disable 000-default (localhost) & enable 001-semawi (semawi)
RUN a2dissite 000-default
RUN a2ensite 001-semawi

CMD ["/usr/sbin/apache2", "-D",  "FOREGROUND"]

CMD ["/usr/local/bin/entrypoint.sh"]
