#!/bin/bash

    function firstdeployment {
        CHECK_STACK=$(docker stack ls --format "{{title .Name}}" | grep -ohi "${DOCKER_SWARM_STACK_NAME}" )
        if [ "${CHECK_STACK,,}" = "${DOCKER_SWARM_STACK_NAME,,}" ]; then
            echo "END Stack ${DOCKER_SWARM_STACK_NAME} was cofigured before"
        else
            # Create network
            docker network create -d overlay --attachable prd-net --label prd-net
        
            # Create volumes
            docker volume create ${PRD_WP_PATH} --label ${PRD_WP_PATH}
            docker volume create ${PRD_DB_PATH} --label ${PRD_DB_PATH}
            docker volume create ${PRD_DB_BACKUP_PATH} --label ${PRD_DB_BACKUP_PATH}

            # Define temporal variables
            export ENVIRONMENT_NAME="fistdeploy"
            export BUILD_ID=00

            # Generate build
            docker compose -f ./docker-compose.stg.yml build

            # Tag & Push to registry
            docker image tag stg-wp-stg_db ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_DB}-00
            docker image tag stg-wp-stg_wordpress ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WP}-00
            docker image tag stg-wp-stg_nginx ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_FE}-00
            docker image tag stg-wp-stg_wpcli ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WPCLI}-00

            docker push ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_DB}-00
            docker push ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WP}-00
            docker push ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_FE}-00
            docker push ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WPCLI}-00

            # Remove local images
            docker image rm stg-wp-stg_db
            docker image rm stg-wp-stg_wordpress
            docker image rm stg-wp-stg_nginx
            docker image rm stg-wp-stg_wpcli

            # Deploy docker swarm
            docker stack deploy -c ./docker-compose.prd.yml ${DOCKER_SWARM_STACK_NAME}

            # Add services to networks
            docker service update --network-add prd-net ${PRD_WORDPRESS_DB_HOST}
            docker service update --network-add prd-net ${PRD_WORDPRESS_HOST}
            docker service update --network-add prd-net ${PRD_NGINX_HOST}
            docker service update --network-add prd-net ${PRD_WPCLI_HOST}

            # Update images
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

            # Change Service scale
            # docker service scale ${PRD_WORDPRESS_DB_HOST}=${PRD_DB_REPLICAS}
            # docker service scale ${PRD_WORDPRESS_HOST}=${PRD_REPLICAS}
            # docker service scale ${PRD_NGINX_HOST}=${PRD_REPLICAS}
            # docker service scale ${PRD_WPCLI_HOST}=${PRD_DB_REPLICAS}

            # Start monitoring services
            docker compose -f docker-compose-prdmon.yml up -d --build


            echo "END Stack ${DOCKER_SWARM_STACK_NAME} configuration with ${PRD_REPLICAS} replicas"
        fi 
        }

    # Check swarm status
    case "$(docker info --format '{{.Swarm.LocalNodeState}}')" in
        inactive)
            echo "Node is not in a swarm cluster"
            docker swarm init
            firstdeployment
            exit 0;;
        pending)
            echo "ERROR: Node is not in a swarm cluster"
            exit 1;;
        active)
            echo "Node is in a swarm cluster"
            firstdeployment
            exit 0;;
        locked)
            echo "ERROR: Node is in a locked swarm cluster"
            exit 1;;
        error)
            echo "ERROR: Node is in an error state"
            exit 1;;
        *)
            echo "Unknown state $(docker info --format '{{.Swarm.LocalNodeState}}')"
            exit 1;;
    esac