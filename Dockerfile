FROM mediawiki:1.31.1
MAINTAINER Anders Barfod <anba14@frederiksberg.dk>
LABEL version="2018"

# We'll need the deb-src repositories since we're apt-get build-dep'ing
# python-lxml as part of getting gc2smwdaemon's virtualenv prepped
# COPY sources.list.d/jessie-deb-src.list \
#      /etc/apt/sources.list.d/jessie-deb-src.list

# Get stack up
# RUN apt-get update && \
#     apt-get -y install mysql-client apache2 curl php git php-mbstring php-pear \
#     php-mysql php-pgsql libapache2-mod-php virtualenv cron freetds-bin \
#     tdsodbc php-odbc unixodbc odbcinst graphviz graphviz-dev imagemagick && \
#     apt-get -y build-dep python-lxml

# Copy over the Mediawiki configs needed
RUN mkdir /etc/semawi/
COPY composer.local.json /etc/semawi/composer.local.json
COPY db.sql /etc/semawi/db.sql
ADD 001-semawi.conf /etc/apache2/sites-available/001-semawi.conf

# Installing the GC2 daemon
# COPY scripts/installgc2daemon.sh /opt/installgc2daemon.sh
# COPY scripts/syncgc2.sh /opt/syncgc2.sh
# COPY gc2 /opt/gc2
# RUN sh /opt/installgc2daemon.sh

# Entrypoint setting up extensions
COPY scripts/entrypoint.sh /usr/local/bin/
CMD ["/usr/local/bin/entrypoint.sh"]
