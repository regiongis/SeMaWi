# Installing SeMaWi

This guide assumes you have intermediate understanding of docker
concepts and basic usage.

## Building the SeMaWi image

1. Download this repository.
2. Stand in the parent directory of the directory containing `docker-compose.yml`
4. Apply the configuration changes listed below.
5. Issue the following command: `docker-compose up -d` or use `make build`.

## Deployment configuration

As part of the `docker-compose up` command, a couple og mutable data will be mounted for you to the running container:

1. `LocalSettings.php`
2. Logo file

Versions of these files in the `res` folder distributed with the source.

Please make sure you review the provided configuration files to adapt the system to your needs. Notably, you will want to secure the following settings in `LocalSettings.php`:

- `$wgSecretKey`
- `$wgUpgradeKey`
- `$wgServer`

In the docker host, you should be able to access the SeMaWi container
now through your browser, with an address like
`http://semawi.example.com`. Please note that you **must** have
entered a correct address for `$wgServer$` as explained in the section below;
otherwise, all wiki pages appear empty. A default user _SeMaWi_
(member of groups _SysOp_ and _Bureaucrat_) has been created for you
with the case-sensitive password `SeMaWiSeMaWi`. You should change
this password as your first action in the running system.

### Localsettings.php

Set `$wgServer` to the external address of the container like so:

```php
$wgServer="http://semawi.example.com";
```

You must edit the `$wgSMTP` in `LocalSettings.php` to reflect where the SMTP server is which SeMaWi can use.

If you're running SeMaWi in production, you will need to edit the line in `LocalSettings.php` which looks like `enableSemantics( 'localhost' );`, replacing localhost with the domain name you are using.

## Optional features

### Migration of content

This section describes the process for migrating content from a SeMaWi to a newly established docker container.

#### Approach A: lots of pages which are not in recognised categories, lots of local user accounts

When migrating content to a newly deployed docker build, we are essentially moving the wiki. Therefore, we follow the instructions for backing up and updating the wiki, then we re-deploy the SeMaWi XML dump.

1. Back up the old wiki; instructions [here](https://www.mediawiki.org/wiki/Manual:Backing_up_a_wiki).
```bash
# Copy backup to localhost
scp user@host:/srv/semawi/backup/backup.sql path/to/folder

# restore backup in new db container
cat backup.sql | docker exec -i wiki_sql_1 /usr/bin/mysql -u root --password=root wiki
```
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
* Place `backup.sh` from mutables in `/srv/semawi/`
* `chmod +x /srv/semawi/backup.sh` if needed
* Create folder for backup `mkdir /srv/semawi/backup`
* Add `0 0 * * * /srv/semawi/backup.sh` to the root crontab to backup every midtnight

```bash
# Backup
docker exec CONTAINER /usr/bin/mysqldump -u root --password=root DATABASE > backup.sql

# Restore
cat backup.sql | docker exec -i CONTAINER /usr/bin/mysql -u root --password=root DATABASE
```