FROM nginx:latest

ARG NGINX_HOST
ARG NGINX_PORT
ARG WORDPRESS_HOST

USER root
RUN apt update && apt -y upgrade

# By default docker image replaces env variables with values, required put file in /templates folder with *.conf.template name
COPY ./default.conf /etc/nginx/templates/default.conf.template
COPY ./nginx.conf /etc/nginx/nginx.conf