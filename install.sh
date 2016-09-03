#!/bin/sh
apt-get update
apt-get remove -y nano

# install MySQL 5.5
echo "mysql-server-5.5 mysql-server/root_password password isucon" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password isucon" | debconf-set-selections
apt-get install -y mysql-server mysql-common mysql-client
mysql -u root --password=isucon -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('');"
mysql -u root -e "GRANT ALL PRIVILEGES ON isu4_qualifier.* TO isucon@localhost IDENTIFIED BY 'isucon' WITH GRANT OPTION"

# Install nginx
apt-get install -y nginx
apt-get install -y build-essential libxml2-dev libmysqld-dev libssl-dev libreadline-dev pkg-config vim curl git

useradd -d /home/isucon -m isucon

# Install ndenv
cd /home/isucon/
git clone https://github.com/nodenv/nodenv.git /opt/.nodenv
git clone https://github.com/nodenv/node-build.git /opt/.nodenv/plugins/node-build
chown -R isucon: /opt/.nodenv
ln -s /opt/.nodenv/shims /home/isucon/.local

export NODENV_ROOT="/opt/.nodenv"
echo 'export NODENV_ROOT="/opt/.nodenv"' >> /home/isucon/.bashrc
echo 'export NODENV_ROOT="/opt/.nodenv"' >> ~/.bashrc
echo 'export PATH="$NODENV_ROOT/bin:$PATH"' >> /home/isucon/.bashrc
echo 'export PATH="$NODENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(nodenv init -)"' >> /home/isucon/.bashrc
echo 'eval "$(nodenv init -)"' >> ~/.bashrc
exec $SHELL -l

nodenv install 6.5.0
nodenv global 6.5.0

# Add GitHub ssh key
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''

# Get ruby for benchmarker
git clone https://github.com/sstephenson/ruby-build.git /usr/local/ruby-build
cd /usr/local/ruby-build
./install.sh
mkdir -p /home/isucon/.local
chown -R isucon: /home/isucon/.local
/usr/local/bin/ruby-build 2.1.3 /home/isucon/.local/ruby
/home/isucon/env.sh gem install --no-document gondler -v 0.2.0

# Get go for benchmarker
wget https://storage.googleapis.com/golang/go1.3.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.3.linux-amd64.tar.gz
ln -s /usr/local/go/bin/go /usr/bin/
rm -f go1.3.linux-amd64.tar.gz

# Create /home/isucon
git clone https://github.com/fand/isucon4 /home/isucon/isucon4
cd /home/isucon/isucon4
git checkout q
git submodule init && git submodule update

# Build benchmarker
cd /home/isucon/isucon4/benchmarker
/home/isucon/env.sh make debug
mv /home/isucon/isucon4/benchmarker /tmp/
mv /tmp/benchmarker/benchmarker /home/isucon/

# move files
cp /home/isucon/isucon4/ami/files/env.sh /home/isucon/
cp /home/isucon/isucon4/ami/files/nginx.conf /etc/nginx/
cp /home/isucon/isucon4/ami/files/my.cnf /etc/
chmod 755 /home/isucon/env.sh

# Install npm
cd /home/isucon/isucon4/webapp/node
/home/isucon/env.sh npm install

chown -R isucon: /home/isucon/*

service nginx restart
service mysql restart
service irqbalance start

apt-get install -y supervisor
head -n 26 /home/isucon/ami/files/supervisord.conf > /etc/supervisor/supervisord.conf
sed -i -e 's/wheel/root/' /etc/supervisor/supervisord.conf
service supervisor restart

cd /home/isucon/isucon4
./init.sh
