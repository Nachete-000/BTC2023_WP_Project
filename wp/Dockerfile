FROM wordpress:6-fpm

ARG WORDPRESS_DB_HOST
ARG WORDPRESS_DB_USER
ARG WORDPRESS_DB_PASSWORD
ARG WORDPRESS_DB_NAME

# Install plugin (sample to install)
COPY disable-canonical-redirects.php /var/www/html/wp-content/plugins/

# Change owner & permission for plugin to www-data (user WP running)
RUN chown www-data:www-data /var/www/html/wp-content/plugins/disable-canonical-redirects.php
RUN chmod 644 /var/www/html/wp-content/plugins/disable-canonical-redirects.php
