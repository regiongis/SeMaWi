#! /bin/bash

docker stop semawi-mediawiki
certbot renew
cp /etc/letsencrypt/live/iotwiki.dk/fullchain.pem /srv/semawi/certs/fullchain.pem
cp /etc/letsencrypt/live/iotwiki.dk/privkey.pem /srv/semawi/certs/privkey.pem
docker start semawi-mediawiki
