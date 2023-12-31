#!/bin/bash -xe
    docker service update --image ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_DB}:latest ${PRD_WORDPRESS_DB_HOST} \
    --env-add MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
    --env-add MYSQL_DATABASE=${MYSQL_DATABASE} \
    --env-add MYSQL_USER=${MYSQL_USER} \
    --env-add MYSQL_PASSWORD=${MYSQL_PASSWORD} \
    --env-add MYSQL_MON_USER=${MYSQL_MON_USER} \
    --env-add MYSQL_MON_PASSWORD=${MYSQL_MON_PASSWORD}

    docker service update --image ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WP}:latest ${PRD_WORDPRESS_HOST} \
    --env-add WORDPRESS_DB_HOST=${PRD_WORDPRESS_DB_HOST} \
    --env-add WORDPRESS_DB_USER=${WORDPRESS_DB_USER} \
    --env-add WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD} \
    --env-add WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME}

    docker service update --image ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_FE}:latest ${PRD_NGINX_HOST} \
    --env-add NGINX_HOST=${PRD_WORDPRESS_WEBSITE_URL_WITHOUT_HTTP} \
    --env-add NGINX_PORT=${NGINX_PORT} \
    --env-add WORDPRESS_HOST=${PRD_WORDPRESS_HOST}

    docker service update --image ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WPCLI}:latest ${PRD_WPCLI_HOST} \
    --env-add EXTERNAL_NGINX_PORT=${PRD_NGINX_PORT} \
    --env-add NGINX_HOST=${PRD_NGINX_HOST} \
    --env-add NGINX_PORT=${NGINX_PORT} \
    --env-add WORDPRESS_WEBSITE_URL=${PRD_WORDPRESS_WEBSITE_URL} \
    --env-add WORDPRESS_WEBSITE_URL_WITHOUT_HTTP=${PRD_WORDPRESS_WEBSITE_URL_WITHOUT_HTTP} \
    --env-add WORDPRESS_WEBSITE_POST_URL_STRUCTURE=${WORDPRESS_WEBSITE_POST_URL_STRUCTURE} \
    --env-add WORDPRESS_WEBSITE_TITLE=${PRD_WORDPRESS_WEBSITE_TITLE} \
    --env-add WORDPRESS_ADMIN_USERNAME=${WORDPRESS_ADMIN_USERNAME} \
    --env-add WORDPRESS_ADMIN_PASSWORD=${WORDPRESS_ADMIN_PASSWORD} \
    --env-add WORDPRESS_ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL} \
    --env-add WORDPRESS_DB_HOST=${PRD_WORDPRESS_DB_HOST} \
    --env-add WORDPRESS_DB_USER=${WORDPRESS_DB_USER} \
    --env-add WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD} \
    --env-add WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME}