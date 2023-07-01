// Function: credentials_for_id
// Function to check if credentials exists
// Usage: credentials_for_id("jenkins_credentials_id")

import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*

def credentials_for_id(String Id) {
  def username_matcher = CredentialsMatchers.withId(Id)
  def available_credentials =
      CredentialsProvider.lookupCredentials(
        StandardUsernameCredentials.class,
        Jenkins.getInstance(),
        hudson.security.ACL.SYSTEM
      )
  return CredentialsMatchers.firstOrNull(available_credentials, username_matcher)
}

// Function: testfunctionwp
// Function to check if user exists in database
// And wordpress is installed and configured
def testfunctionwp(){
    sh '''#!/bin/bash -xe

    if [ "${ENVIRONMENT_NAME}" == 'dev' ]; then
        DBTEST1=$(docker exec db-${ENVIRONMENT_NAME}-${BUILD_ID} mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_USER}';")
        DBTEST2=$(docker exec db-${ENVIRONMENT_NAME}-${BUILD_ID} mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_MON_USER}';")
    elif [ "${ENVIRONMENT_NAME}" == 'stg' ]; then
        DBTEST1=$(docker exec ${ENVIRONMENT_NAME}-db mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_USER}';")
        DBTEST2=$(docker exec ${ENVIRONMENT_NAME}-db mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_MON_USER}';")
    elif [ "${ENVIRONMENT_NAME}" == 'prd' ]; then
        DBTEST1=$(docker exec $(docker ps -q -f name=${PRD_WORDPRESS_DB_HOST}) mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_USER}';")
        DBTEST2=$(docker exec $(docker ps -q -f name=${PRD_WORDPRESS_DB_HOST}) mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_MON_USER}';")
    fi
    
    if [ "${ENVIRONMENT_NAME}" == 'dev' ]; then
        WPTEST1=$(curl --silent ${DEV_WORDPRESS_WEBSITE_URL}:${DEV_NGINX_PORT}/wp-admin/install.php | grep -oh "${WPINSTALLMESSAGE}")
    elif [ "${ENVIRONMENT_NAME}" == 'stg' ]; then
        WPTEST1=$(curl --silent ${STG_WORDPRESS_WEBSITE_URL}:${STG_NGINX_PORT}/wp-admin/install.php | grep -oh "${WPINSTALLMESSAGE}")
    elif [ "${ENVIRONMENT_NAME}" == 'prd' ]; then
        WPTEST1=$(curl --silent ${PRD_WORDPRESS_WEBSITE_URL}:${PRD_NGINX_PORT}/wp-admin/install.php | grep -oh "${WPINSTALLMESSAGE}")
    fi

    if [ "${DBTEST1}" == "${MYSQL_USER}" ]; then
        echo "INFO: User ${MYSQL_MON_USER} exists exists in ${ENVIRONMENT_NAME} database server db-${ENVIRONMENT_NAME}-${BUILD_ID}."
        DBTESTRESTULT1=0
    elif [ "${DBTEST1}" != "${MYSQL_USER}" ]; then
        echo "ERROR: User ${MYSQL_USER} not exists in ${ENVIRONMENT_NAME} database server db-${ENVIRONMENT_NAME}-${BUILD_ID}."
        DBTESTRESTULT1=1
    fi

    if [ "${DBTEST2}" == "${MYSQL_MON_USER}" ]; then
        echo "INFO: User ${MYSQL_MON_USER} exists in ${ENVIRONMENT_NAME} database server db-${ENVIRONMENT_NAME}-${BUILD_ID}."
        DBTESTRESTULT2=0
    elif [ "${DBTEST2}" != "${MYSQL_MON_USER}" ]; then
        echo "ERROR: User ${MYSQL_MON_USER} not exists in ${ENVIRONMENT_NAME} database server db-${ENVIRONMENT_NAME}-${BUILD_ID}."
        DBTESTRESTULT2=1
    fi
    
    if [ "${WPTEST1}" == "${WPINSTALLMESSAGE}" ]; then
        echo "INFO: WordPress site  installed."
        WPTESTRESTULT1=0
    elif [ "${WPTEST1}" != "${WPINSTALLMESSAGE}" ]; then
        echo "ERROR: WordPress site not installed."
        WPTESTRESTULT1=1
    fi

    if [ ${DBTESTRESTULT1} == 0 ] && [ ${DBTESTRESTULT2} == 0 ] && [ ${WPTESTRESTULT1} == 0 ]; then
        echo "INFO: DB Users & Site Connection Tests Ok."
    else
        echo "ERROR: DB Users & Site Connection Tests failded."
        exit 1
    fi
    '''
}

// Function: loadtestfunction
// Function to check with locust load
def loadtestfunction(){
    sh '''#!/bin/bash

    docker compose -f docker-compose-locust.yml up -d --build --force-recreate master
    docker compose -f docker-compose-locust.yml up --build --scale worker=${LOCUST_SCALE}

    # # Check files ./locust/prd_locustfile.py and stg_locustfile.py with the message response because it's hardcoded
    # # If parameters are different for each env, ensure check response and percentile response with values for each env.
    #if [ "${ENVIRONMENT_NAME}" = "stg"]; then
    #    export LOCUST_AVERAGE_RESPONSE=5000
    #    export LOCUST_PERCENTILE_RESPONSE=5000
    #elif [ "${ENVIRONMENT_NAME}" = "prd" ]; then
    #    export LOCUST_AVERAGE_RESPONSE=5000
    #    export LOCUST_PERCENTILE_RESPONSE=5000
    #fi

    # Fixed values for both:
    export LOCUST_AVERAGE_RESPONSE=5000
    export LOCUST_PERCENTILE_RESPONSE=5000

    export LOCUST_ERROR_RESULT1="Test failed due to failure ratio > 1%"
    export LOCUST_ERROR_RESULT2="Test failed due to average response time ratio > ${LOCUST_AVERAGE_RESPONSE} ms"
    export LOCUST_ERROR_RESULT3="Test failed due to 95th percentile response time > ${LOCUST_PERCENTILE_RESPONSE} ms"

    LOCUST_LOG_RESULT=$(docker logs wp-locust-${ENVIRONMENT_NAME}-master 2>&1 )

    LOCUSTRESULT1=$(echo "${LOCUST_LOG_RESULT}" | grep -oh "${LOCUST_ERROR_RESULT1}" )
    LOCUSTRESULT2=$(echo "${LOCUST_LOG_RESULT}" | grep -oh "${LOCUST_ERROR_RESULT2}" )
    LOCUSTRESULT3=$(echo "${LOCUST_LOG_RESULT}" | grep -oh "${LOCUST_ERROR_RESULT3}" )

    echo "Display log:"
    echo "${LOCUST_LOG_RESULT}"

    if [ "${LOCUSTRESULT1}" = "${LOCUST_ERROR_RESULT1}" ]; then
        echo "${LOCUST_ERROR_RESULT1}"
        exit 1
    elif [ "${LOCUSTRESULT2}" = "${LOCUST_ERROR_RESULT2}" ]; then
        echo "${LOCUST_ERROR_RESULT2}"
        exit 1
    elif [ "${LOCUSTRESULT3}" = "${LOCUST_ERROR_RESULT3}" ]; then
        echo "${LOCUST_ERROR_RESULT3}"
        exit 1
    else
        echo "Load Test OK"
    fi
    '''
}

// Function: dockerstackdeploy
// Function to initizalize docker swarm
// test if docker swarm is configured, if not create and configure networks and storage on first run
def dockerstackdeploy(){
    sh '''#!/bin/bash

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

            # Change Service scale, uncomment this section to scale to desired server number after deployment.
            # docker service scale ${PRD_WORDPRESS_DB_HOST}=${PRD_DB_REPLICAS}
            # docker service scale ${PRD_WORDPRESS_HOST}=${PRD_REPLICAS}
            # docker service scale ${PRD_NGINX_HOST}=${PRD_REPLICAS}
            # docker service scale ${PRD_WPCLI_HOST}=${PRD_DB_REPLICAS}

            # Start monitoring services
            docker compose -f docker-compose-prdmon.yml up -d --build


            echo "END Stack ${DOCKER_SWARM_STACK_NAME} configuration"
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
    '''   
}

// Function: prd_docker_update_xx
// Fucntion update production containers for each service
// db=database
// wp=wordpress
// fe=nginx
// wpcli=wordpress client
// update always in this with order db->wp->fe->wpcli
def prd_docker_update_db(){
    sh '''#!/bin/bash -xe
    docker service update --image ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_DB}:latest ${PRD_WORDPRESS_DB_HOST} \
    --env-add MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
    --env-add MYSQL_DATABASE=${MYSQL_DATABASE} \
    --env-add MYSQL_USER=${MYSQL_USER} \
    --env-add MYSQL_PASSWORD=${MYSQL_PASSWORD} \
    --env-add MYSQL_MON_USER=${MYSQL_MON_USER} \
    --env-add MYSQL_MON_PASSWORD=${MYSQL_MON_PASSWORD}
    '''
    }
def prd_docker_update_wp(){    
    sh '''#!/bin/bash -xe
    docker service update --image ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WP}:latest ${PRD_WORDPRESS_HOST} \
    --env-add WORDPRESS_DB_HOST=${PRD_WORDPRESS_DB_HOST} \
    --env-add WORDPRESS_DB_USER=${WORDPRESS_DB_USER} \
    --env-add WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD} \
    --env-add WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME}
    '''
    }
def prd_docker_update_fe(){
    sh '''#!/bin/bash -xe
    docker service update --image ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_FE}:latest ${PRD_NGINX_HOST} \
    --env-add NGINX_HOST=${PRD_WORDPRESS_WEBSITE_URL_WITHOUT_HTTP} \
    --env-add NGINX_PORT=${NGINX_PORT} \
    --env-add WORDPRESS_HOST=${PRD_WORDPRESS_HOST}
    '''
    }
def prd_docker_update_wpcli(){
    sh '''#!/bin/bash -xe
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
    '''
    }

pipeline {
    agent any

    // Global environment variables
    environment{
        // Docker Services Variables
        DOCKER_REGISTRY_HOST="localhost"
        DOCKER_REGISTRY_PORT=5000
        DOCKER_REG_IMAGE_WPCLI="wpcli"
        DOCKER_REG_IMAGE_DB="database"
        DOCKER_REG_IMAGE_WP="wordpress"
        DOCKER_REG_IMAGE_FE="nginx"
        // Swarm name stack
        DOCKER_SWARM_STACK_NAME="prd"
        // nginx global variables
        NGINX_PORT=80
        DEV_NGINX_PORT=5080
        STG_NGINX_PORT=4080
        PRD_NGINX_PORT=80
        // Other nginx variables in each env dev, stg, prd
            // NGINX_HOST
            // WORDPRESS_HOST
        // mariadb global variables
        MYSQL_DATABASE="wpdb"
        // Other MariaDB variables passed as credentials
            // MYSQL_ROOT_PASSWORD
            // MYSQL_USER
            // MYSQL_PASSWORD
            // MYSQL_MON_USER
            // MYSQL_MON_PASSWORD
        // WordPress variables
        WORDPRESS_DB_NAME="wpdb"
        WORDPRESS_DOMAIN="localhost"
        // Wordpress site URL
        DEV_WORDPRESS_WEBSITE_URL="http://devwp.local"
        STG_WORDPRESS_WEBSITE_URL="http://stgwp.local"
        PRD_WORDPRESS_WEBSITE_URL="http://wp.local"

        DEV_WORDPRESS_WEBSITE_URL_WITHOUT_HTTP="devwp.local"
        STG_WORDPRESS_WEBSITE_URL_WITHOUT_HTTP="stgwp.local"
        PRD_WORDPRESS_WEBSITE_URL_WITHOUT_HTTP="wp.local"

        DEV_WORDPRESS_DB_HOST="dev_db"
        STG_WORDPRESS_DB_HOST="stg_db"
        PRD_WORDPRESS_DB_HOST="prd_db"

        DEV_NGINX_HOST="dev_nginx"
        STG_NGINX_HOST="stg_nginx"
        PRD_NGINX_HOST="prd_nginx"
        PRD_WPCLI_HOST="prd_wpcli"

        // WordPress URL Structure
        WORDPRESS_WEBSITE_POST_URL_STRUCTURE="/blog/%postname%/"
        // Wordpress admin portal user data access and e-mail
        WORDPRESS_ADMIN_EMAIL="admin@wp.local"
        
        DEV_WORDPRESS_HOST="dev_wordpress"
        STG_WORDPRESS_HOST="stg_wordpress"
        PRD_WORDPRESS_HOST="prd_wordpress"

        // Wordpress site tittle for each environment
        DEV_WORDPRESS_WEBSITE_TITLE="DEV-DevOps·"
        STG_WORDPRESS_WEBSITE_TITLE="STG-DevOps~"
        PRD_WORDPRESS_WEBSITE_TITLE="DevOps_BLOG"

        // Docker storage variables for volumes
        DEV_WP_PATH="dev_wp"
        DEV_DB_PATH="dev_db"
        STG_WP_PATH="stg_wp"
        STG_DB_PATH="stg_db"
        STG_DB_BACKUP_PATH="stg_db_backup"
        PRD_WP_PATH="wp"
        PRD_DB_PATH="db"
        PRD_DB_BACKUP_PATH="db_backup"

        // Test Variables
        WPINSTALLMESSAGE="Parece que ya has instalado WordPress"
        OUTPUT_TEST="Output Ok"

        // dev Content Creation
            DEV_TAGS="tagdevone,tagdevtwo,tagdevthree,tagdevfour,tagdevfive,tagdevsix,tagdevseven,tagdeveight,tagdevnine,tagdevten"
            DEV_CONTENT="contentdev1,contentdev2,contentdev3,contentdev4,contentdev5,contentdev6,contentdev7,contentdev8,contentdev9,contentdev10"
            // WP Cli post creation, postnumber, comments, time to wait between comment and random post number creation
            DEV_NUMBERPOST=3
            DEV_NUMBERCOMMENTS=2
            DEV_MAXWAITTIMECOMMENT=2
            DEV_MINWAITTIMECOMMENT=1
            DEV_MAXWAITTIMEPOST=2
            DEV_MINWAITTIMEPOST=1
            DEV_POSTRANDOM="N"
            // time to wait before destroy environment (seconds)
            DEV_TIMETOWAIT=15


        // stg Content Creation
            STG_TAGS="tagstgone,tagstgtwo,tagstgthree,tagstgfour,tagstgfive,tagstgsix,tagstgseven,tagstgeight,tagstgnine,tagstgten"
            STG_CONTENT="contentstg1,contentstg2,contentstg3,contentstg4,contentstg5,contentstg6,contentstg7,contentstg8,contentstg9,contentstg10"
            // WP Cli post creation, postnumber, comments, time to wait between comment and random post number creation
            STG_NUMBERPOST=6 //15
            STG_NUMBERCOMMENTS=4 //5
            STG_MAXWAITTIMECOMMENT=2
            STG_MINWAITTIMECOMMENT=1
            STG_MAXWAITTIMEPOST=2
            STG_MINWAITTIMEPOST=1
            STG_POSTRANDOM="Y"
            // time to wait before destroy environment (seconds)
            STG_TIMETOWAIT=15
    }
    // End environment variables

    
    stages {
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Check Credentials
        // If credentials not exists in Jenkins, skip other deployment stages
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        stage('CHECK CREDENTIALS') {
            when {
                expression { 
                    (env.BRANCH_NAME == 'main'
                    ) && (
                        credentials_for_id('WPDB') == null ||
                        credentials_for_id('WPPORTAL') == null ||
                        credentials_for_id('MYSQLADMIN') == null  ||
                        credentials_for_id('MYSQLMONUSR') == null 
                        )
                }
            }
            steps {
                script {
                    println "Deploy error Branch: ${env.BRANCH_NAME} with password credentials not defined"
                    error "ERROR: Missing credential."
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Deployment stack if not running
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        stage('DEPLOY DOCKER STACK') {
            // Commented variable section:
            // environment{
                // Variables to modify with command line replica number, not in use, see dockerstackdeploy() function
                // PRD_REPLICAS=1
                // PRD_DB_REPLICAS=1
            // }
            when {
                expression { 
                    ( env.BRANCH_NAME == 'main' && 
                        credentials_for_id('WPDB') != null &&
                        credentials_for_id('WPPORTAL') != null &&
                        credentials_for_id('MYSQLADMIN') != null &&
                        credentials_for_id('MYSQLMONUSR') != null
                        )
                }
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'WORDPRESS_DB_USER', passwordVariable: 'WORDPRESS_DB_PASSWORD'),
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'MYSQL_USER', passwordVariable: 'MYSQL_PASSWORD'),
                        usernamePassword(credentialsId: 'WPPORTAL', usernameVariable: 'WORDPRESS_ADMIN_USERNAME', passwordVariable: 'WORDPRESS_ADMIN_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLADMIN', usernameVariable: 'MYSQL_ROOT_USER', passwordVariable: 'MYSQL_ROOT_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLMONUSR', usernameVariable: 'MYSQL_MON_USER', passwordVariable: 'MYSQL_MON_PASSWORD')
                        ]){
                            println "Check stack deploy ${DOCKER_SWARM_STACK_NAME}"
                            // Call to function to check/deploy docker swarm stack config
                            dockerstackdeploy()
                        }
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Deployment dev environment with docker compose
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        stage('DEPLOY DEV ENVIRONMENT'){
            environment{
                ENVIRONMENT_NAME="dev"
                // nginx variables
                NGINX_HOST="devwp.local"
                // WP-CLI Tags / content generation
                TAGS="${DEV_TAGS}"
                CONTENT="${DEV_CONTENT}"
                // WP Cli post creation
                MAXWAITTIMECOMMENT="${DEV_MAXWAITTIMECOMMENT}"
                MINWAITTIMECOMMENT="${DEV_MINWAITTIMECOMMENT}"
                MAXWAITTIMEPOST="${DEV_MAXWAITTIMEPOST}"
                MINWAITTIMEPOST="${DEV_MINWAITTIMEPOST}"
                POSTRANDOM="${DEV_POSTRANDOM}"
                // time to wait before destroy
                TIMETOWAIT="${DEV_TIMETOWAIT}"
            }
            when {
                expression {
                    env.BRANCH_NAME == 'main' && 
                    credentials_for_id('WPDB') != null &&
                    credentials_for_id('WPPORTAL') != null &&
                    credentials_for_id('MYSQLADMIN') != null &&
                    credentials_for_id('MYSQLMONUSR') != null
                    }
                }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'WORDPRESS_DB_USER', passwordVariable: 'WORDPRESS_DB_PASSWORD'),
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'MYSQL_USER', passwordVariable: 'MYSQL_PASSWORD'),
                        usernamePassword(credentialsId: 'WPPORTAL', usernameVariable: 'WORDPRESS_ADMIN_USERNAME', passwordVariable: 'WORDPRESS_ADMIN_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLADMIN', usernameVariable: 'MYSQL_ROOT_USER', passwordVariable: 'MYSQL_ROOT_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLMONUSR', usernameVariable: 'MYSQL_MON_USER', passwordVariable: 'MYSQL_MON_PASSWORD')
                        ]){
                            println "Deploying ${ENVIRONMENT_NAME} environment"
                            println "WordPress Portal user: ${WORDPRESS_ADMIN_USERNAME}"
                            // Start containers database, wordpress and frontend
                            sh 'docker compose -f docker-compose.dev.yml up -d --build dev_db dev_wordpress dev_nginx'
                            // Start wp-cli to configure site, don't use -d to display in jenkins result, wpcli ends run.
                            sh 'docker compose -f docker-compose.dev.yml up --build dev_wpcli'
                        }
                }
            }
            post{
                success {
                    script {
                        println "Deployed ${ENVIRONMENT_NAME} environment"
                    }
                }
                failure {
                    script {
                        println "Error Deploying ${ENVIRONMENT_NAME} environment"
                        println "Removing  ${ENVIRONMENT_NAME} environment"
                        // If failure remove
                        sh 'docker compose -f docker-compose.dev.yml down -v --rmi local'
                        error "Error Deploying ${ENVIRONMENT_NAME} environment"
                    }
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Test dev environment with docker compose
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        stage('TEST DEV ENVIRONMENT') {
            environment{
                ENVIRONMENT_NAME="dev"
                // devnginx variables
                NGINX_HOST="devwp.local"
                // WP-CLI Tags / content generation
                TAGS="${DEV_TAGS}"
                CONTENT="${DEV_CONTENT}"
                // WP Cli post creation
                MAXWAITTIMECOMMENT="${DEV_MAXWAITTIMECOMMENT}"
                MINWAITTIMECOMMENT="${DEV_MINWAITTIMECOMMENT}"
                MAXWAITTIMEPOST="${DEV_MAXWAITTIMEPOST}"
                MINWAITTIMEPOST="${DEV_MINWAITTIMEPOST}"
                POSTRANDOM="${DEV_POSTRANDOM}"
                // Time to wait new post / comment
                TIMETOWAIT="${DEV_TIMETOWAIT}"
            }
            when {
                expression {
                    env.BRANCH_NAME == 'main' && 
                    credentials_for_id('WPDB') != null &&
                    credentials_for_id('WPPORTAL') != null &&
                    credentials_for_id('MYSQLADMIN') != null &&
                    credentials_for_id('MYSQLMONUSR') != null
                    }
                }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'WORDPRESS_DB_USER', passwordVariable: 'WORDPRESS_DB_PASSWORD'),
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'MYSQL_USER', passwordVariable: 'MYSQL_PASSWORD'),
                        usernamePassword(credentialsId: 'WPPORTAL', usernameVariable: 'WORDPRESS_ADMIN_USERNAME', passwordVariable: 'WORDPRESS_ADMIN_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLADMIN', usernameVariable: 'MYSQL_ROOT_USER', passwordVariable: 'MYSQL_ROOT_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLMONUSR', usernameVariable: 'MYSQL_MON_USER', passwordVariable: 'MYSQL_MON_PASSWORD')
                    ]){
                            println "Testing ${ENVIRONMENT_NAME} environment"
                            // Call to function test
                            testfunctionwp()

                            println "Creating content"
                            DEVTESTRESULT = sh (
                                script: 'docker compose -f docker-compose.dev.yml up --build dev_testwpcli | grep -oh "${OUTPUT_TEST}"',
                                returnStdout: true
                                ).trim()

                            if ( DEVTESTRESULT == OUTPUT_TEST ) {
                                println "Content Tests Ok"
                            } else {
                                println "Content Tests Failed"
                                error "Content Tests Failed"
                            }
                    }
                }
            }
            post{
                always {
                    // Destroy dev environment
                    println "Finish ${ENVIRONMENT_NAME} environment"
                    println "Waiting ${TIMETOWAIT} seg to destroy ${ENVIRONMENT_NAME} environment"
                    sh 'sleep "${TIMETOWAIT}"'
                    sh 'docker compose -f docker-compose.dev.yml down -v --rmi local'
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Deployment stg environment with docker compose
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        stage('DEPLOY STG ENVIRONMENT') {
            environment{
                ENVIRONMENT_NAME="stg"
                // nginx variables
                NGINX_HOST="stgwp.local"
                // WP-CLI Tags / content generation
                TAGS="${STG_TAGS}"
                CONTENT="${STG_CONTENT}"
                // WP Cli post creation
                MAXWAITTIMECOMMENT="${STG_MAXWAITTIMECOMMENT}"
                MINWAITTIMECOMMENT="${STG_MINWAITTIMECOMMENT}"
                MAXWAITTIMEPOST="${STG_MAXWAITTIMEPOST}"
                MINWAITTIMEPOST="${STG_MINWAITTIMEPOST}"
                POSTRANDOM="${STG_POSTRANDOM}"
                // time to wait before destroy
                TIMETOWAIT="${STG_TIMETOWAIT}"
            }
            when {
                expression {
                    env.BRANCH_NAME == 'main' && 
                    credentials_for_id('WPDB') != null &&
                    credentials_for_id('WPPORTAL') != null &&
                    credentials_for_id('MYSQLADMIN') != null &&
                    credentials_for_id('MYSQLMONUSR') != null
                    }
                }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'WORDPRESS_DB_USER', passwordVariable: 'WORDPRESS_DB_PASSWORD'),
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'MYSQL_USER', passwordVariable: 'MYSQL_PASSWORD'),
                        usernamePassword(credentialsId: 'WPPORTAL', usernameVariable: 'WORDPRESS_ADMIN_USERNAME', passwordVariable: 'WORDPRESS_ADMIN_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLADMIN', usernameVariable: 'MYSQL_ROOT_USER', passwordVariable: 'MYSQL_ROOT_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLMONUSR', usernameVariable: 'MYSQL_MON_USER', passwordVariable: 'MYSQL_MON_PASSWORD')
                        ]){
                            println "Deploying ${ENVIRONMENT_NAME} environment"
                            println "WordPress Portal user: ${WORDPRESS_ADMIN_USERNAME}"
                            // Start containers database, wordpress and frontend
                            sh 'docker compose -f docker-compose.stg.yml up -d --build --force-recreate stg_db stg_wordpress stg_nginx stg_nginx-exporter stg_mysqld-exporter'

                            // No use -d to display in jenkins result, wpcli ends run.
                            sh 'docker compose -f docker-compose.stg.yml up --build  --force-recreate stg_wpcli'
                        }
                }
            }
            post{
                success {
                    script {
                        println "Deployed ${ENVIRONMENT_NAME} environment"
                    }
                }
                failure {
                    script {
                        println "Error Deploying ${ENVIRONMENT_NAME} environment"
                        println "Removing  ${ENVIRONMENT_NAME} environment"
                        // If failure shutdown
                        sh 'docker compose -f docker-compose.stg.yml down --rmi local'
                        error "Error Deploying ${ENVIRONMENT_NAME} environment"
                    }
                }
            }
        }
        stage('TEST STG ENVIRONMENT') {
            environment{
                ENVIRONMENT_NAME="stg"
                // nginx variables
                NGINX_HOST="stgwp.local"
                NGINX_PORT="${STG_NGINX_PORT}"
                // WP-CLI Tags / content generation
                TAGS="${STG_TAGS}"
                CONTENT="${STG_CONTENT}"
                // WP Cli post creation
                MAXWAITTIMECOMMENT="${STG_MAXWAITTIMECOMMENT}"
                MINWAITTIMECOMMENT="${STG_MINWAITTIMECOMMENT}"
                MAXWAITTIMEPOST="${STG_MAXWAITTIMEPOST}"
                MINWAITTIMEPOST="${STG_MINWAITTIMEPOST}"
                POSTRANDOM="${STG_POSTRANDOM}"
                // Time to wait new post / comment
                TIMETOWAIT="${STG_TIMETOWAIT}"
                // Locust
                LOCUST_USERS=250
                LOCUST_SPAWN_RATE=5
                LOCUST_RUNTIME=60
                LOCUST_FILE="stg_locustfile.py"
                // Locust scale workers
                LOCUST_SCALE=2
            }
            when {
                expression {
                    env.BRANCH_NAME == 'main' && 
                    credentials_for_id('WPDB') != null &&
                    credentials_for_id('WPPORTAL') != null &&
                    credentials_for_id('MYSQLADMIN') != null &&
                    credentials_for_id('MYSQLMONUSR') != null
                }
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'WORDPRESS_DB_USER', passwordVariable: 'WORDPRESS_DB_PASSWORD'),
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'MYSQL_USER', passwordVariable: 'MYSQL_PASSWORD'),
                        usernamePassword(credentialsId: 'WPPORTAL', usernameVariable: 'WORDPRESS_ADMIN_USERNAME', passwordVariable: 'WORDPRESS_ADMIN_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLADMIN', usernameVariable: 'MYSQL_ROOT_USER', passwordVariable: 'MYSQL_ROOT_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLMONUSR', usernameVariable: 'MYSQL_MON_USER', passwordVariable: 'MYSQL_MON_PASSWORD')
                    ]){
                            println "Testing ${ENVIRONMENT_NAME} environment"
                            // Call to function test
                            testfunctionwp()

                            // Launch docker compose wp-cli-test instance to create content without -d parameter
                            // display in jenkins result and capture, because can not run docker logs instance, because instance ends at finish of the process without result.
                            // Capture output to variable to generate test correct or not.
                            // The code can be changed with a sh script, see sample in dev section

                            println "Creating content"
                            STGTESTRESULT = sh (
                                script: 'docker compose -f docker-compose.stg.yml up --build stg_testwpcli | grep -oh "${OUTPUT_TEST}"',
                                returnStdout: true
                                ).trim()

                            if ( STGTESTRESULT == OUTPUT_TEST ) {
                                println "Content Tests Ok"
                            } else {
                                println "Content Tests Failed"
                                error "Content Tests Failed"
                            }
                            // Launch locust to test environment and check locust result
                            loadtestfunction()
                        }
                    }
                }
            post{
                success {
                    script {
                        println "${ENVIRONMENT_NAME} environment deployed"
                    }
                }
                failure {
                    script {
                        println "Waiting ${TIMETOWAIT} seg to destroy ${ENVIRONMENT_NAME} environment"
                        sh 'sleep "${TIMETOWAIT}"'
                        sh 'docker compose -f docker-compose.stg.yml down'
                    }
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Deployment prd environment
        // Update registry images
        // Update images
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        stage('DEPLOY PRD ENVIRONMENT') {
            environment{
                ENVIRONMENT_NAME="prd"
                // nginx variables
                NGINX_HOST="wp.local"
            }
            when {
                expression {
                    env.BRANCH_NAME == 'main' && 
                    credentials_for_id('WPDB') != null &&
                    credentials_for_id('WPPORTAL') != null &&
                    credentials_for_id('MYSQLADMIN') != null &&
                    credentials_for_id('MYSQLMONUSR') != null
                }
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'WORDPRESS_DB_USER', passwordVariable: 'WORDPRESS_DB_PASSWORD'),
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'MYSQL_USER', passwordVariable: 'MYSQL_PASSWORD'),
                        usernamePassword(credentialsId: 'WPPORTAL', usernameVariable: 'WORDPRESS_ADMIN_USERNAME', passwordVariable: 'WORDPRESS_ADMIN_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLADMIN', usernameVariable: 'MYSQL_ROOT_USER', passwordVariable: 'MYSQL_ROOT_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLMONUSR', usernameVariable: 'MYSQL_MON_USER', passwordVariable: 'MYSQL_MON_PASSWORD')
                        ]){
                            println "Deploying images to registry ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}"
                            sh 'docker compose -f docker-compose.stg.yml build'
                            
                            // Tag & Upload images to Local Registry
                            // localhost:5000 host not require auth.
                            println "Uploading image ${DOCKER_REG_IMAGE_WPCLI}"
                            sh "docker image tag stg-wp-stg_wpcli ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WPCLI}"
                            sh "docker push ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WPCLI}"
                            sh "docker image rm stg-wp-stg_wpcli"
                            println "Uploading image ${DOCKER_REG_IMAGE_FE}"
                            sh "docker image tag stg-wp-stg_nginx ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_FE}"
                            sh "docker push ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_FE}"
                            sh "docker image rm stg-wp-stg_nginx"
                            println "Uploading image ${DOCKER_REG_IMAGE_WP}"
                            sh "docker image tag stg-wp-stg_wordpress ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WP}"
                            sh "docker push ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_WP}"
                            sh "docker image rm stg-wp-stg_wordpress"
                            println "Uploading image ${DOCKER_REG_IMAGE_DB}"
                            sh "docker image tag stg-wp-stg_db ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_DB}"
                            sh "docker push ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}/${DOCKER_REG_IMAGE_DB}"
                            sh "docker image rm stg-wp-stg_db"

                            println "Deployed images to registry ${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT} "

                            // Create database backup in other volume before update
                            println "Creating database backup ${PRD_WORDPRESS_DB_HOST} wpdb-${BUILD_ID}"

                            sh 'docker exec $(docker ps -q -f name=${PRD_WORDPRESS_DB_HOST}) mkdir -p /mnt/backup/wpdb-${BUILD_ID}'
                            sh 'docker exec $(docker ps -q -f name=${PRD_WORDPRESS_DB_HOST}) mariabackup --backup --databases=wpdb --target-dir=/mnt/backup/wpdb-${BUILD_ID} --user=root --password=${MYSQL_ROOT_PASSWORD}'
                            sh 'docker exec $(docker ps -q -f name=${PRD_WORDPRESS_DB_HOST}) bash -c "cd /mnt/backup; ls -A1t | tail -n +6 | xargs rm -frd;  ls -1t /mnt/backup/"'

                            // Display docker service
                            sh 'docker service ls'

                            // Deploy to production
                            println "Deploying registry images to production"

                            // Call to functions to update images
                            println "Deploy ${DOCKER_REG_IMAGE_DB}"
                            prd_docker_update_db()

                            println "Deploy ${DOCKER_REG_IMAGE_WP}"
                            prd_docker_update_wp()
                            
                            println "Deploy ${DOCKER_REG_IMAGE_FE}"
                            prd_docker_update_fe()
                            
                            println "Deploy ${DOCKER_REG_IMAGE_WPCLI}"
                            prd_docker_update_wpcli()
                        }
                }
            }
            post{
                success {
                    script {
                        // Display docker service
                        sh 'docker service ls'
                        println "${ENVIRONMENT_NAME} environment deployed"
                    }
                }
                failure {
                    script {
                        // If failure, rollback images
                        println "Error Deploying ${ENVIRONMENT_NAME} environment"
                        println "Rollback ${ENVIRONMENT_NAME} environment"
                        sh "docker service rollback ${PRD_WORDPRESS_DB_HOST}"
                        sh "docker service rollback ${PRD_WORDPRESS_HOST}"
                        sh "docker service rollback ${PRD_NGINX_HOST}"
                        sh "docker service rollback ${PRD_WPCLI_HOST}"
                        // Display docker service after rollback
                        sh 'docker service ls'
                    }
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////        
        // Test Stage
        // Check if credentials exists in database
        // Deploy wp-cli-test image and generate content, check if content created it's ok for dev/stg
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////        
        stage('TEST PRD ENVIRONMENT') {
            environment{
                ENVIRONMENT_NAME="prd"
                // nginx variables
                NGINX_HOST="wp.local"
                NGINX_PORT="${PRD_NGINX_PORT}"
                // Locust variables
                LOCUST_USERS=250
                LOCUST_SPAWN_RATE=5
                LOCUST_RUNTIME=60
                LOCUST_FILE="prd_locustfile.py"
                // Locust scale workers
                LOCUST_SCALE=2
            }
            when {
                expression {
                    env.BRANCH_NAME == 'main' && 
                    credentials_for_id('WPDB') != null &&
                    credentials_for_id('WPPORTAL') != null &&
                    credentials_for_id('MYSQLADMIN') != null &&
                    credentials_for_id('MYSQLMONUSR') != null
                }
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'WORDPRESS_DB_USER', passwordVariable: 'WORDPRESS_DB_PASSWORD'),
                        usernamePassword(credentialsId: 'WPDB', usernameVariable: 'MYSQL_USER', passwordVariable: 'MYSQL_PASSWORD'),
                        usernamePassword(credentialsId: 'WPPORTAL', usernameVariable: 'WORDPRESS_ADMIN_USERNAME', passwordVariable: 'WORDPRESS_ADMIN_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLADMIN', usernameVariable: 'MYSQL_ROOT_USER', passwordVariable: 'MYSQL_ROOT_PASSWORD'),
                        usernamePassword(credentialsId: 'MYSQLMONUSR', usernameVariable: 'MYSQL_MON_USER', passwordVariable: 'MYSQL_MON_PASSWORD')
                        ]){
                            println "Test ${ENVIRONMENT_NAME} envirnoment"

                            // Call to function test
                            testfunctionwp()
                            // Launch locust to test environment and check locust result
                            loadtestfunction()
                        }
                }
            }
            post{
                success {
                    script {
                        println "Finisth ${ENVIRONMENT_NAME} test. Environment deployed"
                    }
                }
                failure {
                    script {
                        // If failure, rollback images
                        println "Error Deploying ${ENVIRONMENT_NAME} environment"
                        println "Rollback ${ENVIRONMENT_NAME} environment"
                        sh "docker service rollback ${PRD_WORDPRESS_DB_HOST}"
                        sh "docker service rollback ${PRD_WORDPRESS_HOST}"
                        sh "docker service rollback ${PRD_NGINX_HOST}"
                        sh "docker service rollback ${PRD_WPCLI_HOST}"
                    }
                }
            }
        }
    }
}
