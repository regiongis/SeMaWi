#!/bin/bash

# set -e

if [ ! -d "/var/www/wiki/extensions" ]; then

    LOCALSETTINGS="/var/www/wiki/LocalSettings.php"
    SED="/bin/sed"

    # config
    mv /etc/semawi/composer.local.json /var/www/html/composer.local.json
    chown www-data:www-data /var/www/html/composer.local.json

    echo Waiting for SQL
    until mysqladmin -h sql -u wiki -pwiki ping &>/dev/null; do
        sleep 0.5
    done

    # Database
    mysql -h sql -u wiki -pwiki wiki < /etc/semawi/db.sql

    # Composer
    echo "--> Installing composer ..."
    cd /var/www/html/
    curl -sS https://getcomposer.org/installer | php
    php /var/www/html/composer.phar update

    # GeSHi syntax hl
    echo "--> Installing GeSHi ..."
    cd /var/www/html/extensions/SyntaxHighlight_GeSHi/
    php /var/www/html/composer.phar update --no-dev

    # DataTransfer
    echo "--> Installing DataTransfer ..."
    cd /var/www/html/extensions/
    git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/DataTransfer
    cd /var/www/html/extensions/DataTransfer
    git checkout REL1_31

    # HeaderTabs
    echo "--> Installing HeaderTabs ..."
    cd /var/www/html/extensions/
    git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/HeaderTabs
    cd /var/www/html/extensions/HeaderTabs
    git checkout REL1_31

    # ImagesLoaded
    echo "--> Installing ImagesLoaded ..."
    cd /var/www/html/extensions/
    git clone https://github.com/enterprisemediawiki/ImagesLoaded

    # EditUser
    echo "--> Installing EditUser ..."
    cd /var/www/html/extensions/
    git clone https://github.com/wikimedia/mediawiki-extensions-EditUser
    mv mediawiki-extensions-EditUser EditUser
    cd /var/www/html/extensions/EditUser
    git checkout REL1_31

    # ExternalData
    echo "--> Installing ExternalData ..."
    cd /var/www/html/extensions
    git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/ExternalData
    cd /var/www/html/extensions/ExternalData
    git checkout REL1_31

    # RevisionSlider
    echo "--> Installing RevisionSlider ..."
    cd /var/www/html/extensions
    git clone https://github.com/wikimedia/mediawiki-extensions-RevisionSlider
    mv mediawiki-extensions-RevisionSlider RevisionSlider
    cd /var/www/html/extensions/RevisionSlider
    git checkout REL1_31

    # OdbcDatabase
    echo "--> Installing OdbcDatabase ..."
    cd /var/www/html/extensions
    git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/OdbcDatabase
    cd /var/www/html/extensions/OdbcDatabase
    git checkout REL1_31

    # Maintenance
    echo "--> Installing Maintenance ..."
    cd /var/www/html/extensions
    git clone https://github.com/wikimedia/mediawiki-extensions-Maintenance
    mv mediawiki-extensions-Maintenance Maintenance
    cd /var/www/html/extensions/Maintenance
    git checkout REL1_31

    # PlantUML
    echo "--> Installing PlantUML ..."
    cd /var/www/html/extensions
    git clone https://github.com/pjkersten/PlantUML
    curl -L https://downloads.sourceforge.net/project/plantuml/plantuml.jar -o /usr/local/plantuml.jar

    # Visual Editor
    echo "--> Installing Visual Editor ..."
    cd /var/www/html/extensions
    git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/VisualEditor
    cd /var/www/html/extensions/VisualEditor
    git checkout REL1_31
    git submodule update --init

    # Pear upgrading
    echo "--> Upgrading Pear ..."
    pear upgrade --force --alldeps https://pear.php.net/get/PEAR-1.10.4 # TODO: Look into this version
    pear channel-upgrade pear.php.net
    pear upgrade --force
    pear install Mail Net_SMTP

    php /var/www/html/maintenance/createAndPromote.php --force --bureaucrat \
        --sysop SeMaWi SeMaWiSeMaWi
fi

rm -f /var/run/apache2.pid

exec apache2-foreground
