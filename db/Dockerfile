# Some ubuntu distributions use 10.11.2 and mysqladmin doen't work. Forced to use this:
FROM mariadb:10.11.3

ARG MYSQL_ROOT_PASSWORD
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG MYSQL_MON_USER
ARG MYSQL_MON_PASSWORD

USER root
RUN apt update && apt -y upgrade
RUN mkdir /mnt/backup

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mariadbd"]