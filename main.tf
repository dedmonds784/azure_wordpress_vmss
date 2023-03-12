terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.46.0"
    }
  }
}

data "azurerm_resource_group" "client_resource_group" {
  name = local.environment_resource_group
}

data "azurerm_client_config" "current" {
}

resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  numeric = false
}

locals {
  client_tag                 = lower(trimspace(var.client_name))
  environment_resource_group = "${var.client_resource_group}-${var.environment_prefix}"

  wordpress_config = <<-EOT
    #cloud-config
    package_upgrade: true
    packages:
      - nginx
      - php-curl
      - php-gd
      - php-intl
      - php-mbstring
      - php-soap
      - php-xml
      - php-xmlrpc
      - php-zip
      - php-fpm
      - php-mysql
      - nfs-common

    write_files:
    - path: /tmp/wp-config.php
      content: |
          <?php
          define('DB_NAME', 'wordpress');
          define('DB_USER', 'wordpress');
          define('DB_PASSWORD', 'w0rdpr3ss@p4ss');
          define('DB_HOST', '${azurerm_mysql_server.wordpress_database_server.fqdn}');
          \$table_prefix = 'wp_';
          if ( ! defined( 'ABSPATH' ) ) {
            define( 'ABSPATH', __DIR__ . '/' );
          }
          require_once ABSPATH . 'wp-settings.php';
          ?>


    - path: /tmp/wordpress.conf
      content: |
      server {
          listen 80;
          server_name _;
          root /data/nfs/wordpress;

          index index.html index.htm index.php;

          location / {
              try_files \$uri \$uri/ /index.php\$is_args\$args;
          }

          location ~ \.php$ {
              include snippets/fastcgi-php.conf;
              fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
          }

          location = /favicon.ico { log_not_found off; access_log off; }
          location = /robots.txt { log_not_found off; access_log off; allow all; }
          location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
            expires max;
            log_not_found off;
          }

          location ~ /\.ht {
              deny all;
          }

      }

    runcmd: 
      - mkdir -p /data/nfs/wordpress
      - mount -t nfs ${azurerm_storage_account.wordpress_storage_account.name}.file.core.windows.net:/${azurerm_storage_account.wordpress_storage_account.name}/${var.client_tag}wpstorageshare${var.environment_prefix} /data/nfs -o vers=4,minorversion=1,sec=sys
      - wget http://wordpress.org/latest.tar.gz -P /data/nfs/wordpress
      - tar xzvf /data/nfs/wordpress/latest.tar.gz -C /data/nfs/wordpress --strip-components=1
      - cp /tmp/wp-config.php /data/nfs/wordpress/wp-config.php
      - cp /tmp/wordpress.conf  /etc/nginx/conf.d/wordpress.conf
      - chown -R www-data:www-data /data/nfs/wordpress
      - rm /etc/nginx/sites-enabled/default
      - rm /etc/nginx/sites-available/default
      - systemctl restart nginx
  EOT
}

resource "local_file" "wordpress_config" {
  filename = "${path.module}/wordpress.conf"
  content  = local.wordpress_config
}