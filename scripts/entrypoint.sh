#!/bin/bash

set -e

if [ ! -d "/var/www/wiki/extensions" ]; then

   LOCALSETTINGS="/var/www/wiki/LocalSettings.php"
   SED="/bin/sed"

   # Install Mediawiki
   curl -o /tmp/mediawiki.tar.gz \
   https://releases.wikimedia.org/mediawiki/1.27/mediawiki-1.27.3.tar.gz
   tar xvf /tmp/mediawiki.tar.gz -C /var/www/wiki/ --strip 1
   chown -R root:root /var/www/wiki
   chown -R www-data:www-data /var/www/wiki/images/

   # Install the config and database
   mv /etc/semawi/composer.local.json /var/www/wiki/composer.local.json
   chown www-data:www-data /var/www/wiki/composer.local.json

   # wait for mysql container to be ready
   until mysqladmin -h semawi-mysql -u wiki -pwiki ping &>/dev/null; do
       echo -n "."; sleep 0.2
   done

   # Seed the database
   mysql -h semawi-mysql -u wiki -pwiki wiki < /etc/semawi/db.sql

   # Install composer and run its dependencies
   cd /var/www/wiki/
   curl -sS https://getcomposer.org/installer | php
   /usr/bin/php /var/www/wiki/composer.phar update

   # install GeSHi syntax highlighting
   cd /var/www/wiki/extensions/SyntaxHighlight_GeSHi/
   php /var/www/wiki/composer.phar update --no-dev
   # Install DataTransfer

   cd /var/www/wiki/extensions/
   git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/DataTransfer.git
   cd /var/www/wiki/extensions/DataTransfer
   git checkout -q REL1_27

   # Install HeaderTabs
   cd /var/www/wiki/extensions/
   git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/HeaderTabs.git
   cd /var/www/wiki/extensions/HeaderTabs
   git checkout -q REL1_27

   # Install MasonryMainPage
   cd /var/www/wiki/extensions/
   git clone https://github.com/enterprisemediawiki/MasonryMainPage.git
   cd MasonryMainPage
   git checkout -q 9837244ccf70f3823e8f5366045e1637e65bd993

   # Install ImagesLoaded
   cd /var/www/wiki/extensions/
   git clone https://github.com/enterprisemediawiki/ImagesLoaded.git

   # Install EditUser
   cd /var/www/wiki/extensions/
   git clone https://github.com/wikimedia/mediawiki-extensions-EditUser.git
   mv mediawiki-extensions-EditUser EditUser
   cd /var/www/wiki/extensions/EditUser
   git checkout -q REL1_27

   # Install ExternalData
   cd /var/www/wiki/extensions/
   git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/ExternalData
   cd /var/www/wiki/extensions/ExternalData
   git checkout -q REL1_27

   # Install RevisionSlider
   cd /var/www/wiki/extensions/
   git clone https://github.com/wikimedia/mediawiki-extensions-RevisionSlider.git
   mv mediawiki-extensions-RevisionSlider RevisionSlider
   cd /var/www/wiki/extensions/RevisionSlider
   git checkout -q REL1_27

   # Install OdbcDatabase
   cd /var/www/wiki/extensions/
   git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/OdbcDatabase.git
   cd /var/www/wiki/extensions/OdbcDatabase
   git checkout -q REL1_27
   # der er en lille fejl i ODBC udvidelsen som skal fixes
   # Se https://www.mediawiki.org/wiki/Extension:OdbcDatabase#Possible_code_changes
   $SED -i'' "s/public static function getSoftwareLink/public function getSoftwareLink/" \
	/var/www/wiki/extensions/OdbcDatabase/OdbcDatabase.body.php

   # Install Maintenance
   cd /var/www/wiki/extensions/
   git clone https://github.com/wikimedia/mediawiki-extensions-Maintenance.git
   mv mediawiki-extensions-Maintenance Maintenance
   cd /var/www/wiki/extensions/Maintenance
   git checkout -q REL1_27

   # Install PlantUML
   cd /var/www/wiki/extensions/
   git clone https://github.com/pjkersten/PlantUML.git
   curl -L https://downloads.sourceforge.net/project/plantuml/plantuml.jar -o /usr/local/plantuml.jar

   # Install NewSignupPage
   cd /var/www/wiki/extensions/
   git clone https://github.com/wikimedia/mediawiki-extensions-NewSignupPage.git
   mv mediawiki-extensions-NewSignupPage NewSignupPage
   cd /var/www/wiki/extensions/NewSignupPage
   git checkout -q REL1_27

   cd /var/www/wiki/extensions/NewSignupPage/i18n
   echo "{
   \"@metadata\": {
      \"authors\": []
   },
   \"shoutwiki-loginform-tos\": \"Jeg accepterer IoTwikis [http://iotwiki.dk/index.php?title=Code_of_Conduct Code of Conduct]\",
   \"shoutwiki-must-accept-tos\": \"Du skal acceptere webstedets Code of Conduct for at kunne oprette en konto\"
}" > da.json

   # Configure QuestyCaptcha
   cd /var/www/wiki/extensions/ConfirmEdit/QuestyCaptcha/i18n
   echo "{
   \"@metadata\": {
      \"authors\": []
   },
   \"questycaptcha-desc\": \"Questy CAPTCHA generator til Confirm Edit\",
   \"questycaptcha-addurl\": \"Dine ændringer inkluderer ny eksterne links.\nUdfyld venligst CAPTCHA ([[Special:Captcha/help|mere info]]):\",
   \"questycaptcha-badlogin\": \"Fejl i login. Udfyld venligst CAPTCHA ([[Special:Captcha/help|mere info]]):\",
   \"questycaptcha-createaccount\": \"Udfyld venligst CAPTCHA for at oprette en bruger ([[Special:Captcha/help|mere info]]):\",
   \"questycaptcha-create\": \"Udfyld venligst CAPTCHA for at oprette en ny side ([[Special:Captcha/help|mere info]]):\",
   \"questycaptcha-edit\": \"Udfyld venligst CAPTCHA for at redigere denne side ([[Special:Captcha/help|mere info]]):\",
   \"questycaptcha-sendemail\": \"Udfyld venligst CAPTCHA ([[Special:Captcha/help|mere info]]):\",
   \"questycaptchahelp-text\": \"Denne wiki benytter CAPTCHAs til at undgå spam og bots. Du kan opleve at skulle udfylde CAPTCHAs i flere situationer, herunder ved oprettelse af brugere og redigering af sider.\"
}" > da.json
   cd /

   # Update php pear and install a couple of dependencies
   pear upgrade --force --alldeps http://pear.php.net/get/PEAR-1.10.4
   pear channel-update pear.php.net
   pear upgrade --force
   pear install Mail Net_SMTP

   # We'll need a Sysop/Beaureaucrat
   php /var/www/wiki/maintenance/createAndPromote.php --force --bureaucrat \
       --sysop SeMaWi SeMaWiSeMaWi

   # We'll need a bot for the GC2 sync
   php /var/www/wiki/maintenance/createAndPromote.php --force --bureaucrat \
       --sysop --bot Sitebot SitebotSitebot


fi

# Enable apache module for http headers
a2enmod headers

# Enable apache ssl module
a2enmod ssl

# Apache gets grumpy about PID files pre-existing
rm -f /var/run/apache2.pid

exec apache2 -DFOREGROUND
