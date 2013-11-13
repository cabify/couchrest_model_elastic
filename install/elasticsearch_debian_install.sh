#!/usr/bin/env bash

VERSION=0.90.6
BIN_DIR=/usr/share/elasticsearch/bin

# Elasticsearch debian package
if ! dpkg -s elasticsearch | grep -q 'Status' ; then
    cd /tmp
    if [ ! -f elasticsearch-$VERSION.deb ] ; then
        wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$VERSION.deb
    fi
    sudo dpkg -i elasticsearch-$VERSION.deb
    sudo service elasticsearch start
else
    echo "ElasticSearch $VERSION already installed"
    cd ./
fi

# Plugins
if ! $BIN_DIR/plugin -l | grep -q 'head' ; then
    sudo $BIN_DIR/plugin -install mobz/elasticsearch-head
else
    echo " * head plugin already installed"
fi
if ! $BIN_DIR/plugin -l | grep -q 'river-couchdb' ; then
    sudo $BIN_DIR/plugin -install elasticsearch/elasticsearch-river-couchdb/1.2.0
else
    echo " * river-couchdb plugin already installed"
fi
if ! $BIN_DIR/plugin -l | grep -q 'lang-javascript' ; then
    sudo $BIN_DIR/plugin -install elasticsearch/elasticsearch-lang-javascript/1.4.0
else
    echo " * lang-javascript plugin already installed"
fi

sudo service elasticsearch restart

cd -