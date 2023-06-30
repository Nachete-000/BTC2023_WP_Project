FROM wordpress:cli-2.8

# External Variables
ARG WORDPRESS_DOMAIN
ARG EXTERNAL_NGINX_PORT
ARG NGINX_HOST
ARG NGINX_PORT
ARG WORDPRESS_WEBSITE_URL
ARG WORDPRESS_WEBSITE_URL_WITHOUT_HTTP
ARG WORDPRESS_WEBSITE_POST_URL_STRUCTURE
ARG WORDPRESS_WEBSITE_TITLE
ARG WORDPRESS_ADMIN_USERNAME
ARG WORDPRESS_ADMIN_PASSWORD
ARG WORDPRESS_ADMIN_EMAIL
ARG WORDPRESS_DB_HOST
ARG WORDPRESS_DB_NAME
ARG WORDPRESS_DB_USER
ARG WORDPRESS_DB_PASSWORD
ARG MYSQL_INITDB_SKIP_TZINFO


# Install make tool
USER root
# Make is required
# Fortune for generate random comments
# rig for generate random names
RUN apk add --no-cache make fortune

# Add the wait script to the image
ENV WAIT_VERSION 2.7.2
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /wait
RUN chmod +x /wait

# Add Makefile to scripts dir
ADD ./entrypoint.sh /scripts/
RUN chmod +x /scripts/entrypoint.sh

ENTRYPOINT [ "/scripts/entrypoint.sh" ]
USER 33:33
CMD ["wp", "shell"]