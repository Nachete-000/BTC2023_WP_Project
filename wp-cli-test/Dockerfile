FROM wordpress:cli-2.8

# External Variables
ARG WORDPRESS_DB_HOST
ARG WORDPRESS_DB_USER
ARG WORDPRESS_DB_PASSWORD
ARG WORDPRESS_DB_NAME
ARG BRANCH_NAME
ARG BUILD_ID
ARG TAGS
ARG CONTENT
ARG NUMBERPOST
ARG NUMBERCOMMENTS
ARG MAXWAITTIMECOMMENT
ARG MINWAITTIMECOMMENT
ARG MAXWAITTIMEPOST
ARG MINWAITTIMEPOST
ARG POSTRANDOM


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

# Copy image files with text for post
COPY ./img/*.jpg /tmp/img/

# Add Makefile to scripts dir
ADD ./entrypoint.sh /scripts/
RUN chmod +x /scripts/entrypoint.sh

ENTRYPOINT [ "/scripts/entrypoint.sh" ]
USER 33:33
CMD ["wp", "shell"]