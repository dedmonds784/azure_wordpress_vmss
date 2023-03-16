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
          define('DB_NAME', 'wordpressdb');
          define('DB_USER', '${database_user}');
          define('DB_PASSWORD', '${database_password}');
          define('DB_HOST', '${database_fqdn}');
          $table_prefix = 'wp_';
          if ( ! defined( 'ABSPATH' ) ) {
            define( 'ABSPATH', __DIR__ . '/' );
          }
          require_once ABSPATH . 'wp-settings.php';
          ?>


    - path: /tmp/wordpress.conf
      content: |
        server {
            listen 80;
            root /data/nfs/wordpress;
            index index.html index.htm index.php;
            server_name _;

            location / {
                try_files $uri $uri/ /index.php$is_args$args;
            }

            location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
            }

            location = /favicon.ico { 
                log_not_found off; 
                access_log off; 
            
            }

            location = /robots.txt {
                log_not_found off;
                access_log off;
                allow all;
            }

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
      - mount -t nfs ${wordpress_storage_account_name}.file.core.windows.net:/${wordpress_storage_account_name}/${client_tag}wpstorageshare${environment_prefix} /data/nfs -o vers=4,minorversion=1,sec=sys
      - wget http://wordpress.org/latest.tar.gz -P /data/nfs/wordpress
      - tar xzvf /data/nfs/wordpress/latest.tar.gz -C /data/nfs/wordpress/ --strip-components=1
      - cp /tmp/wp-config.php /data/nfs/wordpress/wp-config.php
      - cp /tmp/wordpress.conf  /etc/nginx/conf.d/wordpress.conf
      - mkdir /data/nfs/wordpress/sites-enabled
      - ln -s /etc/nginx/conf.d/wordpress.conf /data/nfs/wordpress/sites-enabled/wordpress.conf
      - chown -R www-data:www-data /data/nfs/wordpress
      - chmod -R 755 /data/nfs/wordpress/*
      - rm /etc/nginx/sites-enabled/default
      - rm /etc/nginx/sites-available/default
      - mkdir /etc/systemd/system/nginx.service.d
      - printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
      - systemctl daemon-reload
      - systemctl restart nginx