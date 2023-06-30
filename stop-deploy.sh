#/bin/bash

# # Import Set variables
# grep -oP 'export \K[^=]+' ./.envstandalone

function downservices {
    docker service rm "${DOCKER_SWARM_STACK_NAME}"
    docker compose --env-file ./.envstandalone -f ./docker-compose.stg.yml down -v --rmi local
    docker compose --env-file ./.envstandalone -f ./docker-compose.dev.yml down -v --rmi local
    docker compose --env-file ./.envstandalone -f ./docker-compose-prdmon.yml down -v --rmi local
    docker compose --env-file ./.envstandalone -f ./docker-compose-svc.yml down -v --rmi local
}

function removeservices {
    while true; do
        echo "This section remove all your network services and images, continue?"
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*)
                echo "Remove networks"
                docker network rm prd-net stg-net dev-net mon-net
                echo "Remove images, be carefull if you have other images stored"
                docker image prune
                echo "Remove networks, be carefull if you have other networks"
                docker network prune
                echo "Please, remove volumes manually to no lose data"
                echo "Remove unused volumes with: docker volume rm volumename"
                echo "if you are sure that can delete everything use command: docker volume prune -a"
            return 0;;
            [Nn]*)
            echo "Aborted remove data"
            return 1;;
        esac
    done
}

function removegrafanapwd {
    echo "This section remove your grafana password, continue?"
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*)
            rm grafana_admin_pwd -f
            return 0;;
            [Nn]*)
            echo "Aborted remove Grafana Password"
            return 1;;
        esac
    done
}

echo "This script stop and remove all your environment, continue?"
while true; do
    read -p "$* [y/n]: " yn
    case $yn in
        [Yy]*)
        downservices
        removegrafanapwd
        removeservices
        exit 0;;
        [Nn]*)
        echo "Aborted"
        exit 1;;
    esac
done


