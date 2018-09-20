#!/bin/bash

# Update apt
echo "Updating apt…"
sudo apt-get update

# Install the required packages
echo "Installing required packages…"
sudo apt-get install python-dev postgresql libpq-dev python-pip virtualenv git-core jetty9 redis-server

# Setup symlinks for ease of use
mkdir -p ~/ckan/lib
sudo ln -s ~/ckan/lib /usr/lib/ckan
mkdir -p ~/ckan/etc
sudo ln -s ~/ckan/etc /etc/ckan

# Create and activate a virtual environment
echo "Creating and activating virtual environment…"
sudo mkdir -p /usr/lib/ckan/default
sudo chown `whoami` /usr/lib/ckan/default
virtualenv --python=python2 /usr/lib/ckan/default
. /usr/lib/ckan/default/bin/activate || exit 1

# Install setup tools
# (Is this necessary? Should we use a more recent version instead?)
echo "Installing setuptools…"
pip install setuptools==36.1

# Install CKAN
# (This will install CKAN 2.8.1, which is currently the latest stable version.)
pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.8.1#egg=ckan'
pip install -r /usr/lib/ckan/default/src/ckan/requirements.txt

# Deactivate and reactivate the virtual environment
# (Is this necessary to ensure that we're using the venv's paster, etc.?
# Or is this just to prevent human error?)
deactivate || exit 1
. /usr/lib/ckan/default/bin/activate || exit 1

# Start Postgres and make sure it's set to use UTF-8 encoding
echo "Setting Postgres encoding to UTF-8"
sudo service postgresql initdb -E UTF8
sudo service postgresql restart

# Create default Postgres user
# (You'll need to enter a password)
# sudo -u postgres createuser -S -D -R -P ckan_default

sudo -u postgres psql -U postgres -c "CREATE USER ckan_default \
    WITH PASSWORD 'pass' \
    NOSUPERUSER NOCREATEDB NOCREATEROLE;"

# Create ckan_default database owned by the ckan_default user
sudo -u postgres createdb -O ckan_default ckan_default -E utf-8

# Create a directory for the site's config files
echo "Creating directoy for site config files…"
sudo mkdir -p /etc/ckan/default
sudo chown -R `whoami` /etc/ckan/
sudo chown -R `whoami` ~/ckan/etc

# Create the site's CKAN config file
echo "Creating CKAN config file development.ini…"
paster make-config ckan /etc/ckan/default/development.ini

# Specify a site url and give it a better name
sed -i 's/ckan.site_id = default/ckan.site_id = Default Portal (Development)/g' /etc/ckan/default/development.ini
sed -i 's/ckan.site_url =/ckan.site_url = http:\/\/127.0.0.1:5000/g' /etc/ckan/default/development.ini

# Install the real Java, which Solr requires. We know it will work with Java8
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer
sudo apt-get install oracle-java8-set-default
cat >> /etc/environment <<EOL
JAVA_HOME=/usr/lib/jvm/java-8-oracle
JRE_HOME=/usr/lib/jvm/java-8-oracle/jre
EOL

# Set up Solr (a fresh install will already have NO_START=0)
echo "JETTY_HOST=127.0.0.1" >> /etc/default/jetty9
echo "JETTY_PORT=8983" >> /etc/default/jetty9

curl -O http://www-eu.apache.org/dist/lucene/solr/6.6.5/solr-6.6.5.tgz
mv solr-6.6.5.tgz /opt/solr-6.6.5.tgz
tar xzf /opt/solr-6.6.5.tgz solr-6.6.5/bin/install_solr_service.sh --strip-components=2
sudo bash ./install_solr_service.sh /opt/solr-6.6.5.tgz
sudo service solr restart
sudo service jetty9 restart
# Verify that Solr is running
curl -I http://localhost:8983/solr/

