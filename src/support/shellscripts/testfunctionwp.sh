#!/bin/bash -xe

    if [ "${BRANCH_NAME}" == 'dev' ]; then
        DBTEST1=$(docker exec db-${BRANCH_NAME}-${BUILD_ID} mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_USER}';")
        DBTEST2=$(docker exec db-${BRANCH_NAME}-${BUILD_ID} mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_MON_USER}';")
    elif [ "${BRANCH_NAME}" == 'stg' ]; then
        DBTEST1=$(docker exec ${BRANCH_NAME}-db mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_USER}';")
        DBTEST2=$(docker exec ${BRANCH_NAME}-db mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_MON_USER}';")
    elif [ "${BRANCH_NAME}" == 'main' ]; then
        DBTEST1=$(docker exec $(docker ps -q -f name=${PRD_WORDPRESS_DB_HOST}) mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_USER}';")
        DBTEST2=$(docker exec $(docker ps -q -f name=${PRD_WORDPRESS_DB_HOST}) mysql -h localhost -u root -p${MYSQL_ROOT_PASSWORD} -BNe "SELECT User FROM mysql.user WHERE User='${MYSQL_MON_USER}';")
    fi
    
    if [ "${BRANCH_NAME}" == 'dev' ]; then
        WPTEST1=$(curl --silent ${DEV_WORDPRESS_WEBSITE_URL}:${DEV_NGINX_PORT}/wp-admin/install.php | grep -oh "${WPINSTALLMESSAGE}")
    elif [ "${BRANCH_NAME}" == 'stg' ]; then
        WPTEST1=$(curl --silent ${STG_WORDPRESS_WEBSITE_URL}:${STG_NGINX_PORT}/wp-admin/install.php | grep -oh "${WPINSTALLMESSAGE}")
    elif [ "${BRANCH_NAME}" == 'main' ]; then
        WPTEST1=$(curl --silent ${PRD_WORDPRESS_WEBSITE_URL}:${PRD_NGINX_PORT}/wp-admin/install.php | grep -oh "${WPINSTALLMESSAGE}")
    fi

    if [ "${DBTEST1}" == "${MYSQL_USER}" ]; then
        echo "INFO: User ${MYSQL_MON_USER} exists exists in ${BRANCH_NAME} database server db-${BRANCH_NAME}-${BUILD_ID}."
        DBTESTRESTULT1=0
    elif [ "${DBTEST1}" != "${MYSQL_USER}" ]; then
        echo "ERROR: User ${MYSQL_USER} not exists in ${BRANCH_NAME} database server db-${BRANCH_NAME}-${BUILD_ID}."
        DBTESTRESTULT1=1
    fi

    if [ "${DBTEST2}" == "${MYSQL_MON_USER}" ]; then
        echo "INFO: User ${MYSQL_MON_USER} exists in ${BRANCH_NAME} database server db-${BRANCH_NAME}-${BUILD_ID}."
        DBTESTRESTULT2=0
    elif [ "${DBTEST2}" != "${MYSQL_MON_USER}" ]; then
        echo "ERROR: User ${MYSQL_MON_USER} not exists in ${BRANCH_NAME} database server db-${BRANCH_NAME}-${BUILD_ID}."
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