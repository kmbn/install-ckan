#!/bin/bash

# Update apt
echo "Updating apt…"
sudo apt-get update

# Install the required packages
echo "Installing required packages…"
sudo apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv git-core solr-jetty openjdk-8-jdk redis-server

# Create and activate a virtual environment
echo "Creating and activating virtual environment…"
sudo mkdir -p /usr/lib/ckan/default
sudo chown `whoami` /usr/lib/ckan/default
virtualenv --no-site-packages /usr/lib/ckan/default
. /usr/lib/ckan/default/bin/activate

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
deactivate
. /usr/lib/ckan/default/bin/activate

# Start Postgres and make sure it's set to use UTF-8 encoding
echo "Setting Postgres encoding to UTF-8"
sudo service postgresql initdb -E UTF8
sudo service postgresql restart

# Create default Postgres user
# (You'll need to enter a password)
sudo -u postgres createuser -S -D -R -P ckan_default

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
