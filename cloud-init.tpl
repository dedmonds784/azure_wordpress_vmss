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
          define('DB_USER', 'wordpress');
          define('DB_PASSWORD', 'w0rdpr3ss@p4ss');
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
            server_name _;
            root /data/nfs/wordpress;

            index index.html index.htm index.php;

            location / {
                try_files $uri $uri/ /index.php?$args;
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
      - systemctl restart nginx
