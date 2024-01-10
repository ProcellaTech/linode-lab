variable "Linode-lab" {
  type = string
  default = "jjkz7xwzfg67whlw2cex2tedxa"
}

variable "soa_email" {
  type = string
  default = "dns@procella.tech"
}

variable "domain" {
  type = string
  default = "linode.procellab.zone"
}

variable "image" {
  description = "Image to use for Linode instance"
  default = "linode/ubuntu22.04"
}

variable "region" {
  description = "The region where your Linode will be located."
  default = "us-iad"
}

variable "type" {
  description = "Your Linode's plan type."
  default = "g6-nanode-1"
}

variable "a_record" {
  description = "The type of DNS record. For example, `A` records associate a domain name with an IPv4 address."
  default = "A"
}


variable "install_wordpress" {
  description = "install and configure wordpress"
  default = <<-EOF
#!/bin/bash -x


hostnamectl set-hostname wordpress

apt-get update
apt-get install -y wordpress
echo "
<?php
  define( 'DB_NAME', 'wordpress_db' );
  define( 'DB_USER', 'wpdb' );
  define( 'DB_PASSWORD', 'needastrongerpassword' );
  define( 'DB_HOST', '10.0.4.250' );
  define( 'DB_CHARSET', 'utf8' );
  define( 'DB_COLLATE', '' );
  define('WP_ALLOW_REPAIR', true);

  \$table_prefix = 'wp_';
  define( 'WP_DEBUG', false );

  if ( ! defined( 'ABSPATH' ) ) {
   define( 'ABSPATH', __DIR__ . '/' );
  }

  require_once ABSPATH . 'wp-settings.php';

" > /etc/wordpress/config-10.0.4.245.php

sed -i 's!/var/www/html!/usr/share/wordpress!' /etc/apache2/sites-enabled/000-default.conf

systemctl restart apache2


export UI_UM_PASSWORD='965B89oR5f20wSKkIujm'
export GC_PROFILE='default'
wget https://34.121.212.145/guardicore-cas-chain-file.pem --no-check-certificate -O /tmp/guardicore_cas_chain_file.pem
# expected checksum 89e287fc3de1c0ab328185e61a0e8a241974437ca4928a834aa7fada9fbd618d
SHA256SUM_VALUE=`sha256sum /tmp/guardicore_cas_chain_file.pem | awk '{print $1;}'`
export INSTALLATION_CMD='wget --ca-certificate /tmp/guardicore_cas_chain_file.pem -O- https://34.121.212.145 | sudo -E bash'
if [ $SHA256SUM_VALUE == 89e287fc3de1c0ab328185e61a0e8a241974437ca4928a834aa7fada9fbd618d ]; then eval $INSTALLATION_CMD; else echo "Certificate checksum mismatch error"; fi


EOF
}

variable "install_mysql" {
   description = "install and configure mysql for wordpress"
   default = <<-EOF
#!/bin/bash -x

hostnamectl set-hostname mysql

apt-get update
apt-get install -y mysql-server
sed -i 's/bind-address.*$/bind-address      = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

echo "
create database wordpress_db;
create user 'wpdb'@'%' identified by 'needastrongerpassword';
grant all privileges on wordpress_db.* to 'wpdb'@'%';
" | /usr/bin/mysql

export UI_UM_PASSWORD='965B89oR5f20wSKkIujm'
export GC_PROFILE='default'
wget https://34.121.212.145/guardicore-cas-chain-file.pem --no-check-certificate -O /tmp/guardicore_cas_chain_file.pem
# expected checksum 89e287fc3de1c0ab328185e61a0e8a241974437ca4928a834aa7fada9fbd618d
SHA256SUM_VALUE=`sha256sum /tmp/guardicore_cas_chain_file.pem | awk '{print $1;}'`
export INSTALLATION_CMD='wget --ca-certificate /tmp/guardicore_cas_chain_file.pem -O- https://34.121.212.145 | sudo -E bash'
if [ $SHA256SUM_VALUE == 89e287fc3de1c0ab328185e61a0e8a241974437ca4928a834aa7fada9fbd618d ]; then eval $INSTALLATION_CMD; else echo "Certificate checksum mismatch error"; fi


# now disable eth0
#ip link set eth0 down

# can't do it because guardicore
EOF
}

variable "install_nginx" {
  description = "install and configure nginx"
  default = <<-EOF
#!/bin/bash -x


hostnamectl set-hostname nginx

apt-get update
apt-get install -y nginx

echo "
server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/html;
	server_name blog.linode.procellab.zone;
	location / {
		proxy_pass http://10.0.4.245/;
	}
}
" >/etc/nginx/sites-enabled/default

systemctl restart nginx

export UI_UM_PASSWORD='965B89oR5f20wSKkIujm'
export GC_PROFILE='default'
wget https://34.121.212.145/guardicore-cas-chain-file.pem --no-check-certificate -O /tmp/guardicore_cas_chain_file.pem
# expected checksum 89e287fc3de1c0ab328185e61a0e8a241974437ca4928a834aa7fada9fbd618d
SHA256SUM_VALUE=`sha256sum /tmp/guardicore_cas_chain_file.pem | awk '{print $1;}'`
export INSTALLATION_CMD='wget --ca-certificate /tmp/guardicore_cas_chain_file.pem -O- https://34.121.212.145 | sudo -E bash'
if [ $SHA256SUM_VALUE == 89e287fc3de1c0ab328185e61a0e8a241974437ca4928a834aa7fada9fbd618d ]; then eval $INSTALLATION_CMD; else echo "Certificate checksum mismatch error"; fi


EOF
}

#data "template_file" "install_mysql" {
#  template = <<-EOF
#${var.install_mysql}
#echo ${file("wp.mysql")} | base64 -d | gunzip -c | mysql
#EOF
#}
