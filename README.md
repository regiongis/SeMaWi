# Installing SeMaWi

This guide assumes you have intermediate understanding of docker
concepts and basic usage.

## Building the SeMaWi image

1. Download these docker source files.
2. Stand in the parent directory of the directory containing `docker-compose.yml`
4. Apply the configuration changes listed below.
5. Issue the following command: `docker-compose up -d`

## Deployment configuration

As part of the `docker-compose up` command, several types of mutable data will be
mounted for you to the running container:

1. `LocalSettings.php`
2. `php.ini`
3. `images` folder with `www-data:www-data` ownership
4. Logo file
5. gc2 sync configuration file `gc2smw.cfg`
6. Various conf files for unixodbc so the wiki can query a SQL Server

These files are expected to be in the location `/srv/semawi/`. You can find usable
versions of these files in the `mutables` folder distributed with the source.

Please make sure you review the provided configuration files to adapt the system
to your needs. Notably, you will want to secure the following settings:

- `$wgSecretKey`
- `$wgUpgradeKey`
- `$wgServer`

In the docker host, you should be able to access the SeMaWi container
now through your browser, with an address like
`http://semawi.example.com`. Please note that you **must** have
entered a correct address for `$wgServer$` in the earlier section;
otherwise, all wiki pages appear empty. A default user _SeMaWi_
(member of groups _SysOp_ and _Bureaucrat_) has been created for you
with the case-sensitive password `SeMaWiSeMaWi`. You should change
this password as your first action in the running system.

### Setting up SSL
The current setup is geared towards using ***Let's Encrypt*** as CA and obtaining the certificates with `certbot`. A volume is created specifically for the certificates, as `certbot` is run on the host machine. The certificates should be placed in that volume under `/srv/semawi/certs/`. The apache configuration file `001-semawi.conf` expects the certificate and the private to be named `fullchain.pem` and `privkey.pem` respectively. **The server configuration expects these values, and will not work without them**.  The procedure is as follows:

1. Install `certbot` on the host machine. Instructions can be found at [the certbot website](https://certbot.eff.org/).
2. Stop any running instances of SeMaWi or other processes binding to port 80.
3. Run `certbot certonly --standalone` and enter the domain name when prompted.
4. Copy the obtained certificate and key-files into `/srv/semawi/certs`.
5. Start SeMaWi.

#### Setting up automated SSL-certificate renewal
Automatic renewal of the SSL-certificate can be achieved by creating a cronjob that runs the script `cert-renew.sh`. The script will take care of the entire renewal process.

1. Place `cert-renew.sh` into `/srv/semawi/`
2. It may be necessary to run `chmod +xr /srv/semawi/cert-renew.sh`
3. Run `sudo crontab -e` and add `0 4 1 * * sh /srv/semawi/cert-renew.sh` to run the script at 4 on the first of every month. The timing can be modified if desired. 

#### Running without SSL
To use SeMaWi without SSL, change the apache configuration file `001-semawi.conf` such that the VirtualHost on port 80 no longer redirects to SSL, and disable the VirtualHost on port 443.

### Localsettings.php
#### Domain/URL
Set `$wgServer` to the external address of the container like so:

```php
$wgServer="//semawi.example.com";
```



#### Email setup (SMTP)
You must edit the `$wgSMTP` in `LocalSettings.php` to reflect where the SMTP server is which SeMaWi can use. 
```php
$wgSMTP = array(
    'host'     => "mail.example.com", // Where the SMTP server is located. Could also be an IP-address
    'IDHost'   => "example.com",      // Generally this will be the domain name
    'port'     => 465,                // Port to use when connecting to the SMTP server
    'auth'     => true,               // Should we use SMTP authentication (true or false)
    'username' => "my_user_name",     // Username to use for SMTP authentication (if being used)
    'password' => "my_password"       // Password to use for SMTP authentication (if being used)
);
```
The exact settings required depends on your setup. See the [SMTP-manual](https://www.mediawiki.org/wiki/Manual:$wgSMTP#Details) for more details.

The use of email/SMTP depends on the `pear` packages `Mail` and `Net_SMTP`. These should be automatically installed by the script `entrypoint.sh`.

#### Enabling Semantic Mediawiki
If you're running SeMaWi in production, you will need to edit the line in `LocalSettings.php` which looks like `enableSemantics( 'localhost' );`, replacing localhost with the domain name you are using.

## Optional features

### Pulling geodata from a GeoCloud2 instance

First make sure you have followed the instructions for configuring the GC2 sync in SeMaWi. That is documented in this file in the section "GeoCloud2 Import Cronjob".

The image has a script `/opt/syncgc2.sh` which needs to be called in order to initiate a pull from GC2. You will want the docker host to have a cron job for this purpose. An example of such a command could be:

```cron
0 5 * * * docker exec your-container-name /opt/syncgc2.sh
0 6 * * * docker exec your-container-name /usr/bin/php /var/www/wiki/maintenance/runJobs.php
```

Keep in mind, the cronjob will need sufficient privileges to execute docker commands.

### Migration of content

This section describes the process for migrating content from a SeMaWi to a newly established docker container.

#### Approach A: lots of pages which are not in recognised categories, lots of local user accounts

When migrating content to a newly deployed docker build, we are essentially moving the wiki. Therefore, we follow the instructions for backing up and updating the wiki, then we re-deploy the SeMaWi XML dump.

1. Back up the old wiki; instructions [here](https://www.mediawiki.org/wiki/Manual:Backing_up_a_wiki).
2. Deploy the SeMaWi docker according to the instructions on this page.
3. Execute an upgrade; instructions [here](https://www.mediawiki.org/wiki/Manual:Upgrading).
4. Re-read the structure.xml manually from SeMaWi's github in Speciel:Importere (Special:Import)
5. Execute `maintenance/rebuildall.php` and `maintenance/runJobs.php`
6. Remember to `chown -R www-data:www-data /var/www/wiki/images/` in the docker image (with docker exec) after moving the image directory contents.

#### Approach B: accounts are external, no uncategorised pages to move

1. From the old wiki, use Special:Export to obtain XML dumps of all the pages in the categories we want transferred
2. Deploy the SeMaWi docker according to the instructions on this page.
3. Import the XML dumps in the newly deployed SeMaWi container using Speciel:Importere (Special:Import)

### Logo

You will likely want to change your logo. Follow the guidelines [here](https://www.mediawiki.org/wiki/Manual:$wgLogo) to incorporate your logo.

### Data Model

I recommend you examine the list of Forms to identify which parts of the SeMaWi functionality is required in your case. You can link to the Categories created by these Forms in MediaWiki:Sidebar.

### MediaWiki Skin

This dockerized version of SeMaWi ships with the [Chameleon skin](https://www.mediawiki.org/wiki/Skin:Chameleon). To activate it, find the line in `LocalSettings.php` which says:

`$wgDefaultSkin = "vector";`

and change it to

`$wgDefaultSkin = "chameleon";`

### Backup
#### XML
It is possible to [Export](https://www.mediawiki.org/wiki/Help:Export) and [Import](https://www.mediawiki.org/wiki/Manual:Importing_XML_dumps) templates, forms, properties.

#### MySQL
If backup of the Wiki is needed following steps vil setup a cronjob, which dumps MySQL data from the container to the host every night. 

- Place `backup.sh` from `scripts/` in `/srv/semawi/`
- `chmod +x /srv/semawi/backup.sh` if needed
- Create folder for backup `mkdir /srv/semawi/backup`
- Add `0 0 * * * sh /srv/semawi/backup.sh` to the root crontab to backup every midtnight

```bash
# Backup
docker exec CONTAINER /usr/bin/mysqldump -u root --password=root DATABASE > backup.sql

# Restore
cat backup.sql | docker exec -i CONTAINER /usr/bin/mysql -u root --password=root DATABASE
```

After restore you might execute:
```bash
docker exec -i semawi-mediawiki php /var/www/wiki/maintenance/rebuildall.php
docker exec -i semawi-mediawiki php /var/www/wiki/maintenance/runJobs.php
```

If you want to delete old backups you can setup following in the crontab.
```bash
@daily find /srv/semawi/backup/* -mtime +15 -exec rm {} \;
```
This deletes all backups older than 15 days.


### GeoCloud2 Import Cronjob

There are four settings you need to modify to activate the [Mapcentia GeoCloud2](https://github.com/mapcentia/geocloud2) geodata table import into SeMaWi. SeMawi exposes the GC2 sync config in a volume, find it with `docker inspect your-container-name`. In this volume you will fine the cfg file, and the following settings need to be set correctly:

1. username: a valid SeMaWi login. The default docker build establishes a login Sitebot for this purpose
2. password: the password for the above bot account; usually SitebotSitebot
3. site: the URL to the SeMaWi container. Unless you know what you are doing, leave it as-is
4. gc2_url: The URL to the GC2 API

When you have done this, you must exec into the container to install the GC2 sync environment:

```bash
docker exec -ti name-of-your-running-container /bin/bash
cd /opt/
./installgc2daemon.sh

```

Having set the integration up, you must instruct the docker host to call the script from the host's cronjob. Refer to the section "Pulling geodata from a GeoCloud2 instance" in this document to see how to do this.

It is strongly recommended you coordinate the time at which the import runs with Mapcentia.

# Cheat sheet
[Change password for at user](https://www.mediawiki.org/wiki/Manual:Resetting_passwords): 

`docker exec -i semawi-mediawiki php /var/www/wiki/maintenance/changePassword.php --user=UserName --password=NewPW`
