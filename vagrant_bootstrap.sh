#!/bin/bash

# mongo sources
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list

sudo apt-get update
sudo apt-get install -y libyajl-dev git-core libpcre3-dev gdb gperf mongodb-org curl

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3 --autolibs=enable --auto-dotfiles
source ~/.bash_profile
rvm use 1.9.3 --default

cd /mush && bundle install

cd /mush && ./configure

cd /mush && make install

cp -n /mush/database.gz.dist /mush/game/data/outdb.gz
cp -n /mush/chatdb.gz.dist /mush/game/data/chatdb.gz
